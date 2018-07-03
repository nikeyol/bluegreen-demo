RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[34;5m'
GREEN='\033[32;5m'
NC='\033[0m' # No Color

app_domain="cfapps.io"
app_host="chris-umbels-app"
app_name_prefix="demo"

# figure out which deployment is currently live (green or blue)
current_deployment=`cf apps |grep ${app_host}.${app_domain} | cut -d ' ' -f 1 | sed "s/${app_name_prefix}-bluegreen-//"`

# determine which deployment to switch to
new_deployment="green"
current_color=${BLUE}
new_color=${GREEN}

if [ "${current_deployment}" == "green" ]; then
  new_deployment="blue"
  current_color=${GREEN}
  new_color=${BLUE}
fi

echo -e "${YELLOW}Current deployment is ${current_color}${current_deployment}${YELLOW}, deploying ${new_color}${new_deployment} ${NC}"

# push the site
cd site
cf push "${app_name_prefix}-bluegreen-${new_deployment}"
cd ..

# do some testing to ensure our deployment worked
content=`curl http://${app_name_prefix}-bluegreen-${new_deployment}.${app_domain}/ |grep Version`

if [[ $content == *"Version"* ]]; then
    echo -e "${YELLOW}Push succeeded, switching deployment to ${new_color}${new_deployment}${NC}"
    # switch MAIN ROUTE to new deployment and destroy old.
    cf map-route "${app_name_prefix}-bluegreen-${new_deployment}" $app_domain -n $app_host
    cf unmap-route "${app_name_prefix}-bluegreen-${current_deployment}" $app_domain -n $app_host
    cf delete -f "${app_name_prefix}-bluegreen-${current_deployment}"
else
    echo -e "${RED}Test failed!"
fi