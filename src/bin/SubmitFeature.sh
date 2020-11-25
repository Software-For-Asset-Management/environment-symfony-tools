#!/usr/bin/env bash
ROOT_DIR=$PWD

echo "Welcome in submit feature script"
echo ""
echo "Before running this script, you need to commit and push all your changes in main project and in ./vendor/sam/"
echo ""
echo "Do you want to continue? (enter to continue)"
read CONFIRM_CONTINUE
if [[ -z "$CONFIRM_CONTINUE" ]]; then

    echo ""
    echo "Checking that no pending changes..."
    echo "Checking that git url are ok..."

    for dir in `ls ./vendor/sam/`;
    do
        cd vendor/sam/$dir

        # Check that all ./vendor/sam/ git point to the right git
        REMOTE_URL=`git remote -v`
        if [[ $REMOTE_URL == *"my-sam/core/"* ]]; then
            # Check that no pending changes
            if ! git diff-index --quiet HEAD --; then
                if ! git merge-base --is-ancestor @{u} HEAD; then
                    BRANCH_NAME=`git rev-parse --abbrev-ref HEAD`
                    echo ""
                    echo "Branch not pushed to origin, pushing it..."
                    echo ""
                    git push --set-upstream origin $BRANCH_NAME
                    echo ""
                fi
                echo ""
                echo "Changes in progress"
                echo ""
                echo "HOW TO FIX"
                echo "=========="
                echo "You need to commit your changes in $dir before running this script."
                echo ""
                exit
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

    echo "Updating composer.json and composer.lock..."
    if hash remake 2>/dev/null; then
        remake -- exec-env php-fpm 'node bin/UpdateSamBundles.js commit'
    else
        make -- exec-env php-fpm 'node bin/UpdateSamBundles.js commit'
    fi

    echo ""
    echo "DONE !"
    echo ""
    echo "We have updated composer.json and composer.lock accordingly to your current branches and last commit in ./vendor/sam/"
    echo "You can now commit the current project and create a MR so that Gitlab CI can run checks on your feature :)"
    echo ""
    echo "Nice day!"
    echo ""

else
    echo ""
    echo "Goodbye!"
    echo ""
fi
