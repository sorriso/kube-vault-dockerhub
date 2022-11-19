start=`date +%s`
logDate=$(date '+%Y-%m-%d')

if [ -f env ]; then
    # Load Environment Variables
    export $(cat env | grep -v '#' | sed 's/\r$//' | awk '/=/ {print $1}' )
fi

nerdctl -n k8s.io pull consul:${CONSUL_VERSION}
nerdctl -n k8s.io pull alpine:${ALPINE_VERSION}

cp ../../certs/ca/ca.pem .

nerdctl build \
   --no-cache \
   --file ./Dockerfile.alpine \
   --build-arg CONSUL_VERSION=${CONSUL_VERSION} \
   --build-arg ALPINE_VERSION=${ALPINE_VERSION} \
   --namespace k8s.io \
   -t l_consul:latest-${CONSUL_VERSION}_alpine_${ALPINE_VERSION} .

end=`date +%s`

runtime=$((end-start))
runtimeh=$((runtime/60))
runtimes=$((runtime-runtimeh*60))

echo "$logDate - Total runtime was : $runtimeh minutes $runtimes seconds"
echo "" >> ./build.log
echo "$logDate - Total runtime was : $runtimeh minutes $runtimes seconds" >> ./build.log
echo ""
