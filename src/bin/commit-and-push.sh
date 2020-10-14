#!/usr/bin/env bash
ROOT_DIR=$PWD

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
                git status
                echo ""
                echo -e "\033[32mThere are pending changes to push in \"$dir\" ! What is your commit message?\033[0m"
                read COMMIT_MESSAGE
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
