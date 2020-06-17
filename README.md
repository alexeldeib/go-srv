# http load test on AKS

This is a sample load test of simple http client and server.

The server always runs in AKS. The client either runs as an AKS pod in
the same cluster as the server, or as a remote client on any machine.

When both pods run in the cluster, they run on separate machines with no
resource limits.

For Azure nodes we use Standard_D16s_v3 with 16 vCPU / 64 GB RAM / 1TB OS disk (P30 disk).

The results for the Windows PC come from a machinewith the following specifications:

- AMD Ryzen Threadripper 3970x (32 core, 3.70 GHz)
- 64 GB RAM
- 1TB Samsung 970 EVO plus M.2 SSD

The Digital Ocean droplet used as a remote client is the general
purpose, 16 CPU / 64GB RAM / 1TB disk. It's comparable to the Windows PC
in hardware.

Throughput/latency are measured by the following command:

```bash
# same in local/remote client
bombardier -c 125 -n 100000 http://LOAD_BALANCER_PUBLIC_IP
```

## Results
|       client     | rps    | throughput (MB/s) | 
| ---------------- | ------ | ----------------- |
| remote - windows |   1640 |   1.92            |
| remote - linux   |   3540 |   4.14            |
| in cluster - pod | 249194 | 298.50            |


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

## In-cluster pod client:
```pwsh
PS C:\Users\alexe\code\go-srv> kubectl logs client-564c879b47-4szvp
Bombarding http://40.119.56.195:8080/ok with 100000 request(s) using 125 connection(s)
 100000 / 100000  100.00% 249194/s 0s
Done!
Statistics        Avg      Stdev        Max
  Reqs/sec    289024.71   72320.61  324559.16
  Latency      457.19us     1.42ms    67.28ms
  HTTP codes:
    1xx - 0, 2xx - 100000, 3xx - 0, 4xx - 0, 5xx - 0
    others - 0
  Throughput:   298.50MB/s
```