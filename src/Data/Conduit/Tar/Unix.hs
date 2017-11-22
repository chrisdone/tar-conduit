{-# LANGUAGE CPP #-}
module Data.Conduit.Tar.Unix
    ( getFileInfo
    , Dir.doesDirectoryExist
    , Posix.createSymbolicLink
    ) where

import qualified System.Directory as Dir
import qualified System.Posix.Files as Posix
import qualified System.Posix.User as Posix
import System.Posix.Types
import System.IO.Error
import Data.Bits
import Data.Conduit.Tar.Types (FileInfo(..), FileType(..))


getFileInfo :: FilePath -> IO FileInfo
getFileInfo fp = do
    fs <- Posix.getSymbolicLinkStatus fp
    let uid = Posix.fileOwner fs
        gid = Posix.fileGroup fs
    uEntry <- Posix.getUserEntryForID uid
    gEntry <- Posix.getGroupEntryForID gid
    (fType, fSize) <-
        case () of
            () | Posix.isRegularFile fs     -> return (FTNormal, Posix.fileSize fs)
               | Posix.isSymbolicLink fs    -> do
                     ln <- Posix.readSymbolicLink fp
                     return (FTSymbolicLink ln, 0)
               | Posix.isCharacterDevice fs -> return (FTCharacterSpecial, 0)
               | Posix.isBlockDevice fs     -> return (FTBlockSpecial, 0)
               | Posix.isDirectory fs       -> return (FTDirectory, 0)
               | Posix.isNamedPipe fs       -> return (FTFifo, 0)
               | otherwise                  -> error $ "Unsupported file type: " ++ fp
    return FileInfo
        { filePath      = fp
        , fileUserId    = uid
        , fileUserName  = Posix.userName uEntry
        , fileGroupId   = gid
        , fileGroupName = Posix.groupName gEntry
        , fileMode      = Posix.fileMode fs .&. 0o7777
        , fileSize      = fSize
        , fileType      = fType
        , fileModTime   = Posix.modificationTime fs
        }
