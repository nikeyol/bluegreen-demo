app_domain="mydomain.com"
app_host="www"
app_name_prefix="demo"

# figure out which deployment is currently live (green or blue)
current_deployment=`cf apps |grep ${app_host}.${app_domain} | awk '{print $1}' | sed  's/${app_name_prefix}-bluegreen-//'`
echo "Current deployment is: ${current_deployment}"

# determine which deployment to switch to
new_deployment="green"

if [ "${current_deployment}" == "green" ]; then
  new_deployment="blue"
fi

# push the site
cd site
cf push "${app_name_prefix}-bluegreen-${new_deployment}"
cd ..

# do some testing to ensure our deployment worked
content=`curl http://${app_host}.${app_domain}/ |grep Version`

if [[ $content == *"Version"* ]]; then
    echo "Push succeeded, switching deployment to ${new_deployment}"
#switch to new deployment and destroy old.
    cf map-route "${app_name_prefix}-bluegreen-${new_deployment}" $app_domain -n $app_host
    cf unmap-route "${app_name_prefix}-bluegreen-${current_deployment}" $app_domain -n $app_host
    cf delete -f "${app_name_prefix}-bluegreen-${current_deployment}"
fi