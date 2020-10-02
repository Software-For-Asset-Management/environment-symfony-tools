#!/usr/bin/env bash
: ${ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION?"You need to set ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION env variable, for e.g.: ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION=2"}
ROOT_DIR=$PWD

echo "Lets go with $ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION.x.x"

for dir in `ls ./vendor/sam/`;
do
    cd vendor/sam/$dir

    REMOTE_URL=`git remote -v`
    if [[ $REMOTE_URL == *"my-sam/core/"* ]]; then
        if git diff-index --quiet HEAD --; then
            echo ""
            echo "Checking $dir"

            #checkout and pull origin in order to get last tags if done by somebody else
            git checkout --track origin/$ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION.x --quiet 2> /dev/null
            git checkout $ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION.x --quiet
            git pull --quiet

            #get highest tag number
            VERSION=`git tag -l --sort=-version:refname "$ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION.*" | head -n 1`

            #replace . with space so can split into an array
            VERSION_BITS=(${VERSION//./ })
            VNUM1=${VERSION_BITS[0]}
            VNUM2=${VERSION_BITS[1]}
            VNUM3=${VERSION_BITS[2]}

            # get current hash and see if it already has a tag
            GIT_COMMIT=`git rev-parse $ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION.x`
            NEEDS_TAG=`git describe --contains $GIT_COMMIT`

            #only tag if no tag already (would be better if the git describe command above could have a silent option)
            if [ -z "$NEEDS_TAG" ]; then

                # Print unreleased changelog
                echo ""
                echo "CHANGELOG snippet"
                echo "---------------"
                sed -n '/\[Unreleased\]/,/## \[2/p' CHANGELOG.md
                echo "---------------"
                echo ""

                # Found if it's fix or new feature
                sedOutput=$(sed -n '/\[Unreleased\]/,/## \[2/p' CHANGELOG.md)
                if [[ $sedOutput =~ "### Added" ]]
                then
                    echo "We found that the release contains new features"
                    VNUM2=$((VNUM2+1))
                    VNUM3=0
                else
                  echo "We found that the release NOT contains new features"
                    VNUM3=$((VNUM3+1))
                fi

                # Create new tag
                NEW_TAG="$VNUM1.$VNUM2.$VNUM3"
                echo "Proposed tag: $NEW_TAG. If not correct, press any key or enter if OK"
                read NOTCORRECT
                if [[ ! -z "$NOTCORRECT" ]]; then
                    exit
                fi

                date=$(date '+%Y-%m-%d')
                sed -i "/\[Unreleased\]/s/$/ \n\r## [$NEW_TAG] - $date/" CHANGELOG.md
                if [[ `git status --porcelain` ]]; then
                    git commit -am "Tagging $ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION.x with $NEW_TAG"
                    echo "Tagging $ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION.x with $NEW_TAG"
                    git push
                fi
                git tag -a -m "New version release: $NEW_TAG." $NEW_TAG
                git push --tags
            else
                echo "Last commit of $ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION.x already tagged"
            fi
        else
            echo ""
            echo "!! C H A N G E S   I N   P R O G R E S S !!"
            echo ""
            echo "Can't pull $ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION.x and tag version for $dir, please commit your changes before."
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

# Update composer.lock
echo ""
echo "Updating composer.lock and composer.json with last tags for SAM bundles:"
echo ""

if hash remake 2>/dev/null; then
    remake -- exec php-fpm 'node bin/update-composer.js'
else
    make -- exec php-fpm 'node bin/update-composer.js'
fi
