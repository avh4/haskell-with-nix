import Control.Concurrent.SingleUseVar (newSingleUseVar, readSingleUseVar, setSingleUseVar)
import Data.Maybe (fromMaybe)
import Development.Shake
import Development.Shake.FilePath
import qualified System.Directory

config :: [FilePath] -> Rules () -> IO ()
config shakefileSources rules' = do
  shakefiles <- getDirectoryFilesIO "" shakefileSources
  shakefilesHash <- getHashedShakeVersion shakefiles
  let options =
        shakeOptions
          { shakeChange = ChangeModtimeAndDigest,
            shakeColor = True,
            shakeVersion = shakefilesHash
          }
  shakeArgs options rules'

main :: IO ()
main = do
  followUpCommandVar <- newSingleUseVar @(IO ())
  let queueFollowUpCommand =
        liftIO . setSingleUseVar "Multiple follow-up-commands queued" followUpCommandVar

  -- Run shake
  config
    [ "Shakefile/package.yaml",
      "Shakefile/src//*.hs"
    ]
    (rules queueFollowUpCommand)

  -- Run follow-up commands
  fromMaybe (return ()) =<< readSingleUseVar followUpCommandVar

rules :: (IO () -> Action ()) -> Rules ()
rules followUp = do
  want ["generated", "build", "test", "check"]

  phony "all" $
    need
      [ "generated",
        "docs",
        "build",
        "test",
        "check"
      ]

  phony "generated" $
    need
      [ "{{ cookiecutter.project_name }}.cabal",
        "{{ cookiecutter.project_name }}.nix",
        "Shakefile/build.cabal",
        "Shakefile/default.nix",
        "cabal.project.freeze"
      ]

  let hsFilesSrc =
        [ "src//*.hs",
          "main//*.hs",
          "Shakefile//*.hs"
        ]

  let hsFilesTest =
        [ "test//*.hs"
        ]

  let allHsFiles =
        mconcat
          [ hsFilesSrc,
            hsFilesTest
          ]

  let nixShellNixFiles =
        [ "nix//*.nix",
          "default.nix",
          "shell.nix",
          "{{ cookiecutter.project_name }}.nix",
          "Shakefile/default.nix"
        ]
  let allNixFiles = nixShellNixFiles

  --
  -- build
  --

  phony "build" $ do
    need ["{{ cookiecutter.project_name }}.cabal", "cabal.project.freeze", "_build/nix-shell.ok"]
    cmd_ ["cabal", "--offline", "v2-build"]

  "{{ cookiecutter.project_name }}.cabal" %> \out -> do
    need ["package.yaml", "_build/files_list/src.hs.txt"]
    cmd_ (FileStdout out) "hpack" "-"

  "Shakefile/build.cabal" %> \out -> do
    need ["Shakefile/package.yaml", "_build/files_list/Shakefile/src.hs.txt"]
    cmd_ (Cwd "Shakefile") (FileStdout out) "hpack" "-"

  "_build/files_list//*.txt" %> \out -> do
    let path = dropDirectory1 $ dropDirectory1 $ dropExtension $ dropExtension out
    let ext = takeExtension $ dropExtension out
    filenames <- getDirectoryFiles "." [path <//> "*" <.> ext]
    writeFileChanged out $ unlines filenames

  --
  -- test
  --

  phony "test" $
    need ["test:{{ cookiecutter.project_name }}"]

  phony "test:{{ cookiecutter.project_name }}" $ do
    need
      [ "{{ cookiecutter.project_name }}.cabal",
        "cabal.project.freeze",
        "_build/nix-shell.ok"
      ]
    sourceFiles <-
      getDirectoryFiles "." $
        mconcat
          [ hsFilesSrc,
            hsFilesTest
          ]
    need sourceFiles
    cmd_ ["cabal", "--offline", "v2-test", "{{ cookiecutter.project_name }}:tests"]

  --
  -- check
  --

  phony "check" $
    need
      [ "check:format-hs",
        "check:format-nix"
      ]

  phony "check:format-hs" $ do
    hsFiles <- getDirectoryFiles "" allHsFiles
    let oks = ["_build" </> "format" </> "ormolu" </> f <.> "ok" | f <- hsFiles]
    need oks

  "_build/format/ormolu//*.hs.ok" %> \out -> do
    let source = dropDirectory1 $ dropDirectory1 $ dropDirectory1 $ dropExtension out
    need [source]
    cmd_ "ormolu" "--mode=check" source
    hash <- liftIO $ getHashedShakeVersion [source]
    writeFileChanged out hash

  phony "check:format-nix" $ do
    nixFiles <- getDirectoryFiles "" allNixFiles
    let oks = ["_build" </> "format" </> "nixfmt" </> f <.> "ok" | f <- nixFiles]
    need oks

  "_build/format/nixfmt//*.nix.ok" %> \out -> do
    let source = dropDirectory1 $ dropDirectory1 $ dropDirectory1 $ dropExtension out
    need [source]
    cmd_ "nixfmt" "--verify" "--quiet" source
    hash <- liftIO $ getHashedShakeVersion [source]
    writeFileChanged out hash

  --
  -- autofixes
  --

  phony "autofix" $
    need
      [ "autofix:format-hs",
        "autofix:format-nix"
      ]

  phony "autofix:format-hs" $ do
    hsFiles <- getDirectoryFiles "" allHsFiles
    let format = cmd_ "ormolu" "--mode=inplace"
    mapM_ format hsFiles

  phony "autofix:format-nix" $ do
    nixFiles <- getDirectoryFiles "" allNixFiles
    cmd_ "nixfmt" "--quiet" nixFiles

  --
  -- watch
  --

  phony "watch" $ need ["watch:tests"]

  phony "watch:tests" $ do
    followUp $ cmd_ "ghcid" "--target={{ cookiecutter.project_name }}:test:spec" "-W" "--run"

  phony "watch:warnings" $ do
    followUp $ cmd_ "ghcid" "--target={{ cookiecutter.project_name }}"

  phony "watch:Shakefile" $ do
    followUp $ cmd_ "ghcid" "--target=build"

  --
  -- nix
  --

  "_build/nix-shell.ok" %> \out -> do
    nixFiles <- getDirectoryFiles "" nixShellNixFiles
    otherFiles <-
      getDirectoryFiles
        ""
        [ "nix/sources.json",
          "nix/*.patch"
        ]
    let allFiles = nixFiles <> otherFiles
    need allFiles
    sourcesHash <- liftIO (getHashedShakeVersion allFiles)
    cmd_ ["nix-shell", "--run", "true"]
    writeFileChanged out sourcesHash

  "cabal.project.freeze" %> \out -> do
    need
      [ "{{ cookiecutter.project_name }}.cabal",
        "Shakefile/build.cabal",
        "{{ cookiecutter.project_name }}.nix",
        "Shakefile/default.nix",
        "_build/nix-shell.ok"
      ]
    liftIO $ removeFiles "." [out]
    cmd_ ["nix-shell", "--pure", "--run", "cabal --offline freeze"]

  "{{ cookiecutter.project_name }}.nix" %> \out -> do
    need ["package.yaml"]
    (Stdout rawNix) <- cmd ["cabal2nix", "--hpack", "."]
    cmd_ (FileStdout out) (StdinBS rawNix) "nixfmt" "--quiet"

  "Shakefile/default.nix" %> \out -> do
    need ["Shakefile/package.yaml"]
    (Stdout rawNix) <- cmd (Cwd "Shakefile") ["cabal2nix", "--hpack", "."]
    cmd_ (FileStdout out) (StdinBS rawNix) "nixfmt" "--quiet"

  --
  -- Documentation
  --

  phony "docs" $ do
    genHtmlFiles <-
      fmap (<.> "html")
        <$> getDirectoryFiles
          ""
          [ "Design//*.md",
            "dev/Documentation//*.md"
          ]
    genPngFiles <-
      fmap (<.> "png")
        <$> getDirectoryFiles
          ""
          [ "dev/Documentation//*.plantuml"
          ]
    need $
      mconcat
        [ ["dev/Documentation/Module dependencies.png"],
          genHtmlFiles,
          genPngFiles
        ]

  "//*.md.html" %> \out -> do
    let source = dropExtension out
    need [source]
    cmd_ ["pandoc", source, "-o", out]

  "//*.plantuml.png" %> \out -> do
    let source = dropExtension out
    need [source]
    let plantumlOutput = source -<.> "png"
    cmd_ ["plantuml", "-tpng", source]
    liftIO $ System.Directory.renameFile plantumlOutput out

  "dev/Documentation/Module dependencies.png" %> \out -> do
    need =<< getDirectoryFiles "" hsFilesSrc
    (Stdout dotSource) <-
      cmd
        [ "graphmod",
          "--no-cluster",
          "--prune-edges",
          "--remove-module=Prelude",
          "--no-cabal",
          "-isrc",
          "-imain",
          "Main"
        ]
    cmd_ (StdinBS dotSource) ["dot", "-Tpng", "-o" <> out]
