#!/bin/bash

helpFunction()
{
   echo ""
   echo "Usage: $0 -p projectKey -s sourceHost -d destinationHost -x sourceAPIToken -e sourceUserID -f sourcePassword -y destinationUserID -z destinationPassword"
   echo -e "\t-p projectKey of the required project to be migrated"
   echo -e "\t-s source HOST of the required project to be migrated"
   echo -e "\t-d destination HOST of the required project to be migrated"
   echo -e "\t-x sourceAPIToken to be used, for listing the repos of the project to be migrated"
   echo -e "\t-e sourceUserID to be used, to pull/push of the required project to be migrated"
   echo -e "\t-f sourcePassword to be used, to pull/push of the required project to be migrated"
   echo -e "\t-y destinationUserID to be used, to push of the required project to be migrated"
   echo -e "\t-z destinationPassword to be used, to push of the required project to be migrated"
   exit 1 # Exit script after printing help
}
#function to url encode
rawurlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"    # You can either set a return variable (FASTER) 
  REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p
}

while getopts "p:s:d:x:e:f:y:z:" opt
do
   case "$opt" in
      p ) projKey="$OPTARG" ;;
      s ) sourceHost="$OPTARG" ;;
      d ) destination="$OPTARG" ;;
      x ) sourceAPIToken="$OPTARG" ;;
      e ) sourceUserId="$OPTARG" ;;
      f ) sourcePassword="$OPTARG" ;;	  
      y ) destinationUserID="$OPTARG" ;;
      z ) destinationPassword="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$projKey" ] || [ -z "$sourceHost" ] || [ -z "$destination" ] || [ -z "$sourceAPIToken" ] || [ -z "$sourceUserID" ] || [ -z "$sourcePassword" ] || [ -z "$destinationUserID" ] || [ -z "$destinationPassword" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

# Begin script in case all parameters are correct
echo "$projKey"
echo "$sourceHost"
echo "$destination"

#Getting list of repos in a project
get_repos_list() {
     curl -X GET -H "Authorization: Bearer ${sourceAPIToken}" -H "Content-Type: application/json"  http://${sourceHost}/rest/api/1.0/projects/${projKey}/repos > test.txt

     grep -oP '(?<="slug":").*?(?=","id")' <<< `cat test.txt` > repolist.txt
}

#Creating repo in cloud Bitbucket similar to OnPrem Bitbucket.
create_repo_cloudBB() {

     echo "Add repo creation code snippet"

     curl -X POST --user ${destinationUserID}:${destinationPassword} -H "Content-Type: application/json" --data "{\"name\": \"${1}\",\"scmId\": \"git\",\"forkable\": true}" https://${destination}/rest/api/1.0/projects/${projKey}/repos

}

#Clone repo from OnPrem and migrate to Cloud Bitbucket
#EMAILID and PASSWORD ,if they contain  "@" special character, it should be replaces by "%40"
clone_migrate_repo() {

     git clone --mirror http://${sourceUserID}:${sourcePassword}@${sourceHost}/scm/${projKey}/${1}.git temp-dir
     cd  temp-dir
     git push https://${destinationUserID}:${destinationPassword}@${destination}/scm/${projKey}/${1}.git --all
     git push https://${destinationUserID}:${destinationPassword}@${destination}/scm/${projKey}/${1}.git --tags
     cd ..
     rm -rf temp-dir
}

#############################    SCRIPT EXECUTION STARTS HERE  ##########################################
get_repos_list

if [ -s repolist.txt ]
then
     echo "File not empty"

    for repoName in `cat repolist.txt`
    do
      echo "RepoName is $repoName"
      #create_repo_cloudBB $repoName
      #clone_migrate_repo $repoName
    done

else
     echo "File empty"
fi
