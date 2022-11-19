start=`date +%s`
logDate=$(date '+%Y-%m-%d')

if [ -f env ]; then
    # Load Environment Variables
    export $(cat env | grep -v '#' | sed 's/\r$//' | awk '/=/ {print $1}' )
fi

nerdctl -n k8s.io pull consul:${CONSUL_VERSION}
nerdctl -n k8s.io pull registry.access.redhat.com/ubi8/ubi-minimal:${UBI8_MINIMAL_VERSION}

cp ../../certs/ca/ca.pem .

nerdctl build \
   --no-cache \
   --file ./Dockerfile.ubi8 \
   --build-arg CONSUL_VERSION=${CONSUL_VERSION} \
   --build-arg UBI8_VERSION=${UBI8_MINIMAL_VERSION} \
   --namespace k8s.io \
   -t l_consul:latest-${CONSUL_VERSION}_ubi8_${UBI8_MINIMAL_VERSION} .

end=`date +%s`

runtime=$((end-start))
runtimeh=$((runtime/60))
runtimes=$((runtime-runtimeh*60))

echo "$logDate - Total runtime was : $runtimeh minutes $runtimes seconds"
echo "" >> ./build.log
echo "$logDate - Total runtime was : $runtimeh minutes $runtimes seconds" >> ./build.log
echo ""
