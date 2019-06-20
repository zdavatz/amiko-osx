#!/bin/bash
# Alex Bettarini -  19 Jun 2019
# Copyright © 2019 Ywesee GmbH. All rights reserved.

STEP_REMOVE_SUPPORT_FILES=true
STEP_DOWNLOAD_SUPPORT_FILES=true
STEP_BUILD=true
STEP_ARCHIVE=true
STEP_CREATE_IPA=true
STEP_UPLOAD_APP=true

#-------------------------------------------------------------------------------
TIMESTAMP1=$(date +%Y%m%d)
TIMESTAMP2=$(date +%Y%m%d_%H%M)
WD=$PWD
PILLBOX_ODDB_ORG="http://pillbox.oddb.org"

# default is ~/Library/Developer/Xcode/Archives
# see Xcode->Preferences->Locations->Archives
ARCHIVE_PATH="$WD/../build/Archives/$TIMESTAMP1"

IPA_PATH="$WD/../build/ipa"

#ITC_FILE=itc.conf
#touch $ITC_FILE

security unlock-keychain

#-------------------------------------------------------------------------------
if [ $STEP_REMOVE_SUPPORT_FILES ] ; then
pushd ../AmiKoOSX
for EXT in db html csv ; do
    if ls *.$EXT 1> /dev/null 2>&1; then
        echo Removing *.$EXT
        rm *.$EXT
    fi
done
popd > /dev/null
fi

#-------------------------------------------------------------------------------
if [ $STEP_DOWNLOAD_SUPPORT_FILES ] ; then
pushd ../AmiKoOSX
for LANG in de fr ; do
    wget $PILLBOX_ODDB_ORG/amiko_report_$LANG.html
    
    FILENAME=drug_interactions_csv_$LANG.zip
    wget $PILLBOX_ODDB_ORG/$FILENAME
    unzip $FILENAME
    rm $FILENAME
    
    FILENAME=amiko_frequency_$LANG.db.zip
    wget $PILLBOX_ODDB_ORG/$FILENAME
    unzip $FILENAME
    rm $FILENAME
    
    FILENAME=amiko_db_full_idx_$LANG.zip
    wget $PILLBOX_ODDB_ORG/$FILENAME
    unzip $FILENAME
    rm $FILENAME
done
popd > /dev/null
fi

#-------------------------------------------------------------------------------
if [ $STEP_BUILD ] ; then
pushd ../
for TARGET in AmiKo CoMed ; do
    echo "Build $TARGET"
    xcodebuild build -target $TARGET -configuration Release
done
popd > /dev/null
fi

#-------------------------------------------------------------------------------
if [ $STEP_ARCHIVE ] ; then
pushd ../
mkdir -p $ARCHIVE_PATH
for SCHEME in AmiKo CoMed ; do
    echo "Archive $SCHEME"
    xcodebuild archive \
    -scheme $SCHEME \
    -configuration Release \
    -derivedDataPath "build/DerivedData" \
    -archivePath "$ARCHIVE_PATH/$SCHEME $TIMESTAMP2.xcarchive"
done
popd > /dev/null
fi

#-------------------------------------------------------------------------------
if [ $STEP_CREATE_IPA ] ; then
security unlock-keychain
#PRODUCT_BUNDLE_IDENTIFIER=amikoosx
#PROVISIONING_PROFILE_SPECIFIER="Zeno Davatz"
pushd ../
for f in $ARCHIVE_PATH/*.xcarchive ; do
    echo "Export the .ipa from $f"
    xcodebuild -exportArchive \
        -verbose \
        -archivePath "$f" \
        -exportOptionsPlist $WD/store.plist \
        -exportPath "$IPA_PATH"
done
popd > /dev/null
fi

#-------------------------------------------------------------------------------
if [ $STEP_UPLOAD_APP ] ; then
#source $ITC_FILE
for f in $IPA_PATH/*.ipa ; do
    echo "Validating $f"
    xcrun altool --validate-app --type osx --file "$f" \
        --username "$ITC_USER" --password "$ITC_PASSWORD"

    echo "Uploading to iTC $f"
    xcrun altool --upload-app --type osx --file "$f" \
        --username "$ITC_USER" --password "$ITC_PASSWORD"
done
fi
