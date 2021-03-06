# http load test on AKS

## WARNING

The below setup attempts to eliminate most constraints to make the comparison as fair as possible between clients in various destinations. Besides CPU, RAM, and other common resources, one common issue with clients on AKS is port exhaustion. This setup avoids that problem by managing port re-use. If your scenario requires large numbers of port allocations, be aware of **SNAT exhaustion** and how outbound connections, particularly from VMSS behind a load balancer, work on Azure.

https://docs.microsoft.com/en-us/azure/load-balancer/troubleshoot-outbound-connection#snatexhaust
https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-outbound-connections#lb

## Setup

This is a sample load test of simple http client and server.

The server always runs in AKS. The client either runs as an AKS pod in
the same cluster as the server, or as a remote client on any machine.

When both pods run in the cluster, they run on separate machines with no
resource limits.

For Azure nodes we use Standard_D16s_v3 with 16 vCPU / 64 GB RAM / 1TB
OS disk (P30 disk).

The results for the Windows PC come from a machine with the following
specifications:

- AMD Ryzen Threadripper 3970x (32 core, 3.70 GHz)
- 64 GB RAM
- 1TB Samsung 970 EVO plus M.2 SSD

The Digital Ocean droplet used as a remote client is a general purpose,
16 CPU / 64GB RAM / 1TB disk instance. It's comparable to the Windows PC
in hardware.

External AKS client clusters have the same configuration as the server cluster.

Throughput/latency are measured by the following command:

```bash
# same in local/remote client
bombardier -c 125 -n 100000 http://LOAD_BALANCER_PUBLIC_IP
```

## AKS Configuration

The basic setup is in test.sh. This is not the actual script I used, but
a rough log of commands with 95% of what you would need to reproduce.
Importantly, it contains all details to configure an identical AKS
cluster. The main features for testing here are:

- Standard load balancer
- 1 TB OS disk to avoid disk throttling
- 16 vCPU / 64GB RAM to avoid CPU/RAM bottlenecks
- 3 nodes, so we can schedule the client and server separately

```bash
az aks create \
    -g ${NAME} \
    -n ${NAME} \
    -l "${LOCATION}"  \
    --node-count 3 \
    --node-vm-size Standard_D16s_v3 \
    --node-osdisk-size 1023 \
    -k 1.17.3 \
    --network-plugin azure \
    --enable-vmss \
    --load-balancer-sku standard
```

## Results
|       client     | rps    | throughput (MB/s) | 
| ---------------- | ------ | ----------------- |
| windows desktop |   1640 |   1.92            |
| digital ocean droplet |   3540 |   4.14            |
| Pod in AKS cluster in different Azure region |   2887 |   3.39            |   
| Pod in AKS cluster in same Azure region | 249422 | 305.86            |
| Pod in same AKS cluster, different host | 249567 | 326.05            |

## Windows remote client:
```pwsh
PS C:\Users\alexe> bombardier -c 125 -n 100000 http://40.119.56.195:8080
Bombarding http://40.119.56.195:8080 with 100000 request(s) using 125 connection(s)
 100000 / 100000 [===============================================================] 100.00% 1640/s 1m0s
Done!
Statistics        Avg      Stdev        Max
  Reqs/sec      1642.47    1497.33    6708.17
  Latency       76.15ms     6.01ms   430.31ms
  HTTP codes:
    1xx - 0, 2xx - 100000, 3xx - 0, 4xx - 0, 5xx - 0
    others - 0
  Throughput:     1.92MB/s
```

## Digital Ocean remote linux client:
```bash
root@ubuntu-s-16vcpu-64gb-sfo2-01:~$ bombardier -c 125 -n 100000 http://40.119.56.195:8080
Bombarding http://40.119.56.195:8080 with 100000 request(s) using 125 connection(s)
 100000 / 100000 [===========================================================================================================================================================================] 100.00% 3540/s 28s
Done!
Statistics        Avg      Stdev        Max
  Reqs/sec      3544.44     426.03    8298.89
  Latency       35.28ms     1.67ms    91.82ms
  HTTP codes:
    1xx - 0, 2xx - 100000, 3xx - 0, 4xx - 0, 5xx - 0
    others - 0
  Throughput:     4.14MB/s
```

## AKS cluster, same region:
```bash
Bombarding http://40.119.56.195:8080 with 100000 request(s) using 125 connection(s)
 100000 / 100000  100.00% 2887/s 34s
Done!
Statistics        Avg      Stdev        Max
  Reqs/sec      2902.67     520.17    5393.81
  Latency       43.06ms     1.95ms   141.08ms
  HTTP codes:
    1xx - 0, 2xx - 100000, 3xx - 0, 4xx - 0, 5xx - 0
    others - 0
  Throughput:     3.39MB/s
```

## AKS cluster, same region:
```bash
ace@ace-vm:~/code/go-srv$ kubectl logs client-6858999d56-d67dx
Bombarding http://40.119.56.195:8080 with 100000 request(s) using 125 connection(s)
 100000 / 100000  100.00% 249422/s 0s
Done!
Statistics        Avg      Stdev        Max
  Reqs/sec    282414.47   73553.18  324683.42
  Latency      458.46us     1.22ms    53.65ms
  HTTP codes:
    1xx - 0, 2xx - 100000, 3xx - 0, 4xx - 0, 5xx - 0
    others - 0
  Throughput:   305.86MB/s
```

## In-cluster pod client:
```pwsh
PS C:\Users\alexe\code\go-srv> kubectl logs client-857695d5fb-4fbv2
Bombarding http://40.119.56.195:8080 with 100000 request(s) using 125 connection(s)
 100000 / 100000  100.00% 249567/s 0s
Done!
Statistics        Avg      Stdev        Max
  Reqs/sec    296992.99   74987.42  340537.90
  Latency      426.45us     0.91ms    45.58ms
  HTTP codes:
    1xx - 0, 2xx - 100000, 3xx - 0, 4xx - 0, 5xx - 0
    others - 0
  Throughput:   326.05MB/s
```
