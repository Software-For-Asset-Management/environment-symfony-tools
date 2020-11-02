#!/usr/bin/env bash
#: ${ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION?"You need to set ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION env variable, for e.g.: ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION=2"}

echo "Lets go with $ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION.x branches"

for dir in `ls ./vendor/sam/`;
do
    cd vendor/sam/$dir

    REMOTE_URL=`git remote -v`
    if [[ $REMOTE_URL == *"my-sam/core/"* ]]; then
        git update-index --refresh
        if git diff-index --quiet HEAD --; then
            echo ""
            echo "Checking $dir"
            #fetch origin in order to get last tags if done by somebody else
            git checkout --track origin/$ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION.x --quiet
            git checkout $ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION.x --quiet
            git pull --quiet

            #get highest tag number
            VERSION=`git tag -l --sort=-version:refname "$ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION.0.*" | head -n 1`

            echo "Last tagged version: $VERSION"
        else
            echo ""
            echo "!! C H A N G E S   I N   P R O G R E S S !!"
            echo ""
            echo "Can't pull $ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION.x for $dir, please commit your changes before."
            echo ""
            echo ""
            echo ""
        fi
    else
        echo ""
        echo "Git repo don't point to $dir's git but main project"
        echo ""
        echo "HOW TO FIX"
        echo "=========="
        echo ""
        echo "You need to remove the dir '$dir' and then do composer install with prefer-source in order to download from git:"
        echo ""
        echo "rm -rf vendor/sam/$dir"
        echo "environment composer install --prefer-source"
        echo ""
        exit
    fi

    cd ../../../
done
