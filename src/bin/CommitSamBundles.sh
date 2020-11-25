#!/usr/bin/env bash
ROOT_DIR=$PWD
CHANGELOG_MODE=false
key="$1"
case $key in
    -h|--help)
    echo ""
    echo -e "\033[34mWelcome in commit and push script"
    echo -e "\033[34mThis script will ask you for a commit message and then will loop through all SAM dir and finally push to origin.\033[0m"
    echo ""
    echo -e "By default, the script will NOT ask you for CHANGELOG message, if you want to add text into the CHANGELOG, use \033[33m--changelog\033[0m arg"
    exit
    ;;
    --changelog)
    CHANGELOG_MODE=true
    echo ""
    echo -e "\033[33mChangelog mode enable, we'll ask you changes to put into CHANGELOG.md\033[0m"
    shift # past argument
    ;;
esac

echo ""
echo -e "\033[34mWelcome in commit and push script"
echo -e "\033[34mThis script will ask you for a commit message and then will loop through all SAM dir and finally push to origin."
echo ""
echo -e "\033[33mDo you want to continue? (enter to continue)\033[0m"
read CONFIRM_CONTINUE
if [[ -z "$CONFIRM_CONTINUE" ]]; then
    for dir in `ls ./vendor/sam/`;
    do
        cd vendor/sam/$dir

        # Check that all ./vendor/sam/ git point to the right git
        REMOTE_URL=`git remote -v`
        if [[ $REMOTE_URL == *"my-sam/core/"* ]]; then
            # Check if we have pending changes
            if ! git diff-index --quiet HEAD --; then
                git checkout --track origin/$ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION.x --quiet
                git checkout $ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION.x --quiet
                git pull --quiet

                git status
                echo ""
                if $CHANGELOG_MODE; then
                  echo -e "\033[32mThere are pending changes to push in \"$dir\" !\033[0m"
                  echo ""
                  echo -e "\033[32mWhat's types of your changes [Fixed]: \033[0m"
                  read CHANGES_TYPE
                  CHANGES_TYPE=${CHANGES_TYPE:-Fixed}
                  echo -e "\033[32mWhat's the message?\033[0m"
                  read CHANGELOG_MESSAGE
                  if [ -z "$CHANGELOG_MESSAGE" ]; then
                    echo -e "\033[33mSkipping changelog\033[0m"
                  else
                    echo -e "\033[33mOK, lets add your '$CHANGES_TYPE': '$CHANGELOG_MESSAGE' into 'CHANGELOG.md'\033[0m"
                    sed -i "/\[Unreleased\]/s/$/\n\n### $CHANGES_TYPE\n- $CHANGELOG_MESSAGE/" CHANGELOG.md
                  fi
                fi
                echo ""
                echo -e "\033[32mThere are pending changes to push in \"$dir\"! What is your commit message (if empty we use previous one)?\033[0m"
                read COMMIT_MESSAGE
                if [ -z "$COMMIT_MESSAGE" ] && [ -n "$OLD_COMMIT_MESSAGE" ]; then
                  COMMIT_MESSAGE=$OLD_COMMIT_MESSAGE
                fi
                if [ -z "$OLD_COMMIT_MESSAGE" ]; then
                  OLD_COMMIT_MESSAGE=$COMMIT_MESSAGE
                fi
                echo -e "\033[33mOK, lets commit your message: '$COMMIT_MESSAGE' and then push to origin\033[0m"
                echo ""
                git add .
                git commit --all --m "$COMMIT_MESSAGE"
                git push
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

    echo ""
    echo -e "\033[30;48;5;82m DONE! Have a nice day! \033[0m"
    echo ""

else
    echo ""
    echo -e "\033[30;48;5;82m Good bye! \033[0m"
    echo ""
fi
