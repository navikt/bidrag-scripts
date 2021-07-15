#!/bin/bash
set -x

############################################
#
# Følgende skjer i dette skriptet
# - setter input og kloner bidrag-script (enten branch som tilsvarer branch som bygges, eller main branch)
# - kaller createCucumberShell.sh som bruker createCucumberShell.kts som setter sammen alle argument i en streng som key=value separert med kommaer
# - lager output av av generert script (RUNNER_WORKSPACE/INPUT_FINAL_SHELL_NAME)
#
############################################

if [[ $# < 3 ]]; then
  echo ::error:: "Usage: createCucumberShell.sh <mapped arguments> <github_project_name> <final_shell_file>"
  echo ::error:: "Args: $@"
  exit 1
fi

INPUT_MAPPED_ARGUMENTS=$1
INPUT_GITHUB_PROJECT_NAME=$2
INPUT_FINAL_SHELL_FILE=$3

cd "$RUNNER_WORKSPACE" || exit 1

if [ ! -d bidrag-scripts/.git ]; then
  BRANCH="${GITHUB_REF#refs/heads/}"

  if [[ "$BRANCH" != "main" ]]; then
    FEATURE_BRANCH=$BRANCH
    echo "cloning bidrag-scripts to $PWD"
    IS_SCRIPT_CHANGE=$(git ls-remote --heads $(echo "https://github.com/navikt/bidrag-scripts $FEATURE_BRANCH" | sed "s/'//g") | wc -l)

    if [[ $IS_SCRIPT_CHANGE -eq 1 ]]; then
      echo "Using feature branch: $FEATURE_BRANCH, cloning to $PWD"
      git clone --depth 1 --branch=$FEATURE_BRANCH https://github.com/navikt/bidrag-scripts
    else
      echo "Using /refs/heads/main, cloning to $PWD"
      git clone --depth 1 https://github.com/navikt/bidrag-scripts
    fi
  else
    echo "Using /refs/heads/main, cloning to $PWD"
    git clone --depth 1 https://github.com/navikt/bidrag-scripts
  fi
else
  cd bidrag-scripts || exit 1
fi

if [ -z $RUNNER_WORKSPACE ]; then
  echo ::error:: "No defined workspace for the github runner"
fi

kotlinc -script $RUNNER_WORKSPACE/bidrag-scripts/src/kotlin/createCucumberShell.kts $INPUT_MAPPED_ARGUMENTS

CREATED_SHELL_FILE="$RUNNER_WORKSPACE/$INPUT_FINAL_SHELL_FILE"

if [ ! -f $CREATED_SHELL_FILE ]; then
  echo ::error:: "unable to find created shell: '$CREATED_SHELL_FILE'"
  exit 1
fi

chmod +x $CREATED_SHELL_FILE
echo ::set-output name=created_shell::"$CREATED_SHELL_FILE"
