module Rattletrap.Encode.Content
  ( putContent
  )
where

import Rattletrap.Encode.Cache
import Rattletrap.Encode.ClassMapping
import Rattletrap.Encode.Frame
import Rattletrap.Encode.KeyFrame
import Rattletrap.Encode.List
import Rattletrap.Encode.Mark
import Rattletrap.Encode.Message
import Rattletrap.Encode.Str
import Rattletrap.Encode.Word32le
import Rattletrap.Type.Content
import Rattletrap.Type.Word32le
import Rattletrap.Utility.Bytes

import qualified Data.Binary as Binary
import qualified Data.Binary.Bits.Put as BinaryBits
import qualified Data.Binary.Put as Binary
import qualified Data.ByteString.Lazy as LazyBytes

putContent :: Content -> Binary.Put
putContent content = do
  putList putText (contentLevels content)
  putList putKeyFrame (contentKeyFrames content)
  let streamSize = contentStreamSize content
  putWord32 streamSize
  let
    stream = LazyBytes.toStrict
      (Binary.runPut (BinaryBits.runBitPut (putFrames (contentFrames content)))
      )
  Binary.putByteString
    (reverseBytes (padBytes (word32leValue streamSize) stream))
  putList putMessage (contentMessages content)
  putList putMark (contentMarks content)
  putList putText (contentPackages content)
  putList putText (contentObjects content)
  putList putText (contentNames content)
  putList putClassMapping (contentClassMappings content)
  putList putCache (contentCaches content)
  case contentUnknown content of
    Nothing -> pure ()
    Just unknown -> putWord32 unknown
