{-# LANGUAGE DeriveGeneric #-}

module Rattletrap.ReplicationValue where

import Rattletrap.Attribute
import Rattletrap.ClassPropertyMap
import Rattletrap.CompressedWord
import Rattletrap.Initialization
import Rattletrap.Word32

import qualified Data.Aeson as Aeson
import qualified Data.Binary.Bits.Get as BinaryBit
import qualified Data.Binary.Bits.Put as BinaryBit
import qualified GHC.Generics as Generics

data ReplicationValue
  = SpawnedReplication Bool
                       Word32
                       Initialization
  | UpdatedReplication [Attribute]
  | DestroyedReplication
  deriving (Eq, Generics.Generic, Ord, Show)

instance Aeson.FromJSON ReplicationValue

instance Aeson.ToJSON ReplicationValue

getReplicationValue :: ClassPropertyMap
                    -> CompressedWord
                    -> BinaryBit.BitGet ReplicationValue
getReplicationValue classPropertyMap actorId = do
  isOpen <- BinaryBit.getBool
  if isOpen
    then do
      isNew <- BinaryBit.getBool
      if isNew
        then do
          unknown <- BinaryBit.getBool
          objectId <- getWord32Bits
          case getObjectName classPropertyMap objectId of
            Nothing ->
              fail ("could not get object name for id " ++ show objectId)
            Just objectName ->
              case getClassName objectName of
                Nothing ->
                  fail
                    ("could not get class name for object " ++ show objectName)
                Just className -> do
                  let hasLocation = classHasLocation className
                  let hasRotation = classHasRotation className
                  initialization <- getInitialization hasLocation hasRotation
                  pure (SpawnedReplication unknown objectId initialization)
        else do
          attributes <- getAttributes classPropertyMap actorId
          pure (UpdatedReplication attributes)
    else pure DestroyedReplication

putReplicationValue :: ReplicationValue -> BinaryBit.BitPut ()
putReplicationValue value =
  case value of
    SpawnedReplication unknown objectId initialization -> do
      BinaryBit.putBool True
      BinaryBit.putBool True
      BinaryBit.putBool unknown
      putWord32Bits objectId
      putInitialization initialization
    UpdatedReplication attributes -> do
      BinaryBit.putBool True
      BinaryBit.putBool False
      putAttributes attributes
    DestroyedReplication -> BinaryBit.putBool False
