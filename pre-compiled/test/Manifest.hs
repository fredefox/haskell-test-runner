{-# language OverloadedStrings #-}
{-# language LambdaCase #-}
module Manifest ( Manifest, getTaskId, getManifest ) where

import Data.Aeson ( FromJSON (parseJSON), (.:))
import qualified Data.Aeson as Aeson
import Data.Map (Map)
import qualified Data.Map as Map
import Data.Text (Text)
import qualified Data.Text as Text
import System.Directory
import System.FilePath ((</>))
import Text.Printf (printf)
import Data.Bifunctor (first)

newtype Test = Test
  { taskId :: Maybe Int
  }

instance FromJSON Test where
  parseJSON = Aeson.withObject "test" $ \v -> Test <$> v .: "task_id"

newtype Manifest = Manifest
  { _tests :: Map Text Test
  }

instance FromJSON Manifest where
  parseJSON = Aeson.withObject "manifest" $ \v -> Manifest <$> v .: "tests"

-- | Map test description to task ID based on a manifest.
getTaskId :: Manifest -> String -> Maybe Int
getTaskId (Manifest m) name = Map.lookup (Text.pack name) m >>= taskId

findManifest :: IO (Either String FilePath)
findManifest = do
  d <- getCurrentDirectory
  let p = d </> ".exercism/metadata.json"
  doesFileExist p >>= \case
    False -> pure $ Left $ printf "Could not find manifest: %s" p
    True  -> pure $ Right p

getManifest :: IO (Either String Manifest)
getManifest = findManifest >>= \case
  Right p -> first (printf "Could not decode manifest: %s") <$> Aeson.eitherDecodeFileStrict p
  Left e -> pure $ Left e
