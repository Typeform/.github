#!/bin/bash

urlOfJenkinsServer="${{ inputs.jenkins-server }}"
jenkinsJobName="${{ inputs.jenkins-job }}"
pollTime=${{ inputs.poll-time }}
timeoutValue=${{ inputs.timeout-value }}
verbose=${{ inputs.verbose }}
userName=${{ inputs.jenkins-username }}
password=${{ inputs.jenkins-pat }}

startTime=$(date)
startTimeSeconds=$(date -d "$startTime" +%s) 
endTime=$(date -d "$startTime + $timeoutValue seconds")
endTimeSeconds=$(date -d "$endTime" +%s)

#STEP 1: Trigger the Jenkins Job
#This will return a 201 if the job is created, so we need to test for this

#Generate Crumb value
CRUMB=`curl -s -u "$userName:$password" $urlOfJenkinsServer'/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)'`
TRIGGERJOBJSON=$(curl -I -s -X POST -u "$userName:$password"  -H "$CRUMB" "$urlOfJenkinsServer"/job/"$jenkinsJobName"/build)

if [[ $verbose == true ]]; then
    echo "Results of Triggering The Job:"
    echo "--------------------------------------"
    echo $TRIGGERJOBJSON
    echo "--------------------------------------"
fi

#STEP 2: Did STEP 1 return a 201. If so, continue, if not, stop the script
#Regex to get the queue URL
regex="Location:\s*(http.*\/queue\/item\/([0-9]+)\/)"
#Does the returned value contain 201 Created
if [[ "$TRIGGERJOBJSON" == *"201 Created"* ]]; then
    echo "Job triggered successfully"
    echo "--------------------------------------"
else
    echo "201 Created NOT FOUND. Exiting script with error"
    echo "--------------------------------------"
    exit 1
fi

#STEP 3: Get the queue location from TRIGGERJOBJSON
#Get the queue URL

if [[ $TRIGGERJOBJSON =~ $regex ]]; then
    echo "Queue URL Found."
    echo "--------------------------------------"
    QUEUEURL=${BASH_REMATCH[1]} ;
    if [[ $verbose == true ]]; then
    echo $QUEUEURL ; 
    echo "--------------------------------------"
    fi
else 
    echo "Queue URL NOT FOUND. Exiting script with error"
    echo "--------------------------------------"
    exit 1 
fi

#STEP 4: Get the JobID and URL using the queue location
#Sleep to ensure the job gets started. Sometimes Jenkins has a few seconds pause
sleep 10
BUILDJSON=$(curl -s -X GET -u "$userName:$password"   "$QUEUEURL/api/json?pretty=true")

if [[ $verbose == true ]]; then
    echo "BUILDJSON:"
    echo "--------------------------------------"
    echo $BUILDJSON
    echo "--------------------------------------"
fi

#regex_blocked_status="\"blocked\"\s*:\s*([a-z]+)"
regex="\"blocked\"\s*:\s*([a-z]+).*\"executable\".*?\"number\"\s*:\s*([0-9]+).*?\"url\"\s*:\s*\"(.*?)\""
if [[ $BUILDJSON =~ $regex ]]; then
    if [[ $verbose == true ]]; then
    echo "blocked: " ${BASH_REMATCH[1]} ;
    echo "build number: " ${BASH_REMATCH[2]} ;
    echo "build URL: " ${BASH_REMATCH[3]} ;
    fi
    echo "Job URL retrieved"
    echo "--------------------------------------"
    BUILDURL=${BASH_REMATCH[3]};
    if [[ "${BASH_REMATCH[1]}" == "true" ]]; then
    echo "Build Blocked. Exiting script with error"
    echo "--------------------------------------"
    exit 1
    fi
else
    echo "Build number/URL NOT FOUND. Exiting script with error"
    echo "--------------------------------------"
    exit 1 
fi

#At this point, we have the URL for the build job, so now we can query the status of the job until something happens

#STEP 5: Using the Job URL, query the job until we get some sort of code returned (success, failure, etc) and take appropriate steps
#Potential Values: https://javadoc.jenkins-ci.org/hudson/model/Result.html
#SUCCESS - Build had no errors
#UNSTABLE - Build had some errors but they were not fatal
#FAILURE - Build had a fatal error
#NOT_BUILT - Module was not build
#ABORTED - Manually aborted
#Short pause
sleep 2
echo "Query Build Job Status"
echo "--------------------------------------"
JOBSTATUSJSON=$(curl -s -X GET -u "$userName:$password"   "$BUILDURL/api/json?pretty=true")
if [[ $verbose == true ]]; then
    echo "JOBSTATUSJSON:"
    echo "--------------------------------------"
    echo $JOBSTATUSJSON
    echo "--------------------------------------"
fi

regex="\"building\"\s*:\s*([a-z]+).*?\"result\"\s*:\s*\"?([a-zA-Z]+)\"?."
if [[ $JOBSTATUSJSON =~ $regex ]]; then
    if [[ $verbose == true ]]; then
    echo "Job Status"
    echo "building: " ${BASH_REMATCH[1]} ;
    echo "result: " ${BASH_REMATCH[2]} ;
    fi
    BUILDING=${BASH_REMATCH[1]} ;
    RESULT=${BASH_REMATCH[2]} ;
else
    echo "Build status NOT FOUND. Exiting script with error"
    echo "--------------------------------------"
    exit 1 
fi


while [ "$BUILDING" == "true" ]
do 
    #WAIT pollTime SECONDS
    echo "pause for $pollTime seconds"
    echo "--------------------------------------"
    sleep $pollTime
    currentTimeSeconds=$(date +%s)
    if [[ "$currentTimeSeconds" > "$endTimeSeconds" ]]; then
        echo "Timeout value reached. Exiting with error due to timeout"
        echo "--------------------------------------"
        exit 1
    fi
    #Get the status
    echo "Query Build Job Status"
    echo "--------------------------------------"
    JOBSTATUSJSON=$(curl -s -X GET -u "$userName:$password"   "$BUILDURL/api/json?pretty=true")
    regex="\"building\"\s*:\s*([a-z]+).*?\"result\"\s*:\s*\"?([a-zA-Z]+)\"?."
    if [[ $JOBSTATUSJSON =~ $regex ]]; then
        if [[ $verbose == true ]]; then
        echo "Job Status"
        echo "building: " ${BASH_REMATCH[1]} ;
        echo "result: " ${BASH_REMATCH[2]} ;
        fi
        BUILDING=${BASH_REMATCH[1]} ;
        RESULT=${BASH_REMATCH[2]} ;
    else
        echo "Build status NOT FOUND. Exiting script with error"
        echo "--------------------------------------"
        exit 1 
    fi
done 

#Once I reach here, building is false, so the job isn't running any longer
#Therefor, we can check the result
case $RESULT in
    SUCCESS)
        echo "Build completed successfully"
        exit 0
        ;;
    *)
        echo "Build DID NOT COMPLETE successfully"
        exit 1
        ;;
esac