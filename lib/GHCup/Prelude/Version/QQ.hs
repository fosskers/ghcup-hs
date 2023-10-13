{-# OPTIONS_GHC -Wno-orphans    #-}
{-# LANGUAGE CPP                #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveLift         #-}
{-# LANGUAGE FlexibleInstances  #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TemplateHaskellQuotes #-}


{-|
Module      : GHCup.Utils.Version.QQ
Description : Version quasi-quoters
Copyright   : (c) Julian Ospald, 2020
License     : LGPL-3.0
Maintainer  : hasufell@hasufell.de
Stability   : experimental
Portability : portable
-}
module GHCup.Prelude.Version.QQ where

import           Data.Data
import           Data.Text                      ( Text )
import           Data.Versions
#if !MIN_VERSION_base(4,13,0)
import           GHC.Base
#endif
import           Language.Haskell.TH
import           Language.Haskell.TH.Quote      ( QuasiQuoter(..) )
import           Language.Haskell.TH.Syntax     ( dataToExpQ )
import qualified Data.Text                     as T
import qualified Language.Haskell.TH.Syntax    as TH


#if !MIN_VERSION_base(4,13,0)
deriving instance Lift (NonEmpty Word)
deriving instance Lift (NonEmpty MChunk)
#endif

qq :: (Text -> Q Exp) -> QuasiQuoter
qq quoteExp' = QuasiQuoter
  { quoteExp  = \s -> quoteExp' . T.pack $ s
  , quotePat  = \_ ->
    fail "illegal QuasiQuote (allowed as expression only, used as a pattern)"
  , quoteType = \_ ->
    fail "illegal QuasiQuote (allowed as expression only, used as a type)"
  , quoteDec  = \_ -> fail
    "illegal QuasiQuote (allowed as expression only, used as a declaration)"
  }

vver :: QuasiQuoter
vver = qq mkV
 where
  mkV :: Text -> Q Exp
  mkV = either (fail . show) liftDataWithText . version

mver :: QuasiQuoter
mver = qq mkV
 where
  mkV :: Text -> Q Exp
  mkV = either (fail . show) liftDataWithText . mess

sver :: QuasiQuoter
sver = qq mkV
 where
  mkV :: Text -> Q Exp
  mkV = either (fail . show) liftDataWithText . semver

vers :: QuasiQuoter
vers = qq mkV
 where
  mkV :: Text -> Q Exp
  mkV = either (fail . show) liftDataWithText . versioning

pver :: QuasiQuoter
pver = qq mkV
 where
  mkV :: Text -> Q Exp
  mkV = either (fail . show) liftDataWithText . pvp

-- https://stackoverflow.com/questions/38143464/cant-find-inerface-file-declaration-for-variable
liftText :: T.Text -> Q Exp
liftText txt = AppE (VarE 'T.pack) <$> TH.lift (T.unpack txt)

liftDataWithText :: Data a => a -> Q Exp
liftDataWithText = dataToExpQ (fmap liftText . cast)
