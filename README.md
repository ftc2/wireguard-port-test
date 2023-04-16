# wireguard-port-test
**util for testing forwarded ports through wireguard vpn**

this script creates a temporary `linuxserver/wireguard` container, installs `socat`, and then listens on a specified port. you can then connect remotely to test if your vpn is actually forwarding the port.

i use this to test bittorrent connectability – you get way more peers if your bt client can listen. note that your vpn provider needs to actually support port forwarding, and you have to set that up first for your specific port. i suggest choosing a random port between 10000 and 65353. you want this port to be unique to you for your vpn endpoint.

## installation
```bash
git clone https://github.com/ftc2/wireguard-port-test.git
```

## usage
```
wg_listen.sh CONF PORT [FILTER]
    listen inside of wireguard to test if a forwarded port is working
  args:
    CONF: path to wireguard config file (prepend with './' for relative path)
    PORT: listening port
    FILTER: optional IP range to filter (e.g. 'your_real_ip/32')
            useful if you're getting a lot of spammy traffic on the port,
            and you can't see your test connection
```

## example
pretend your real ip is `142.250.190.110`

```
$ ./wg_listen.sh ./torguard.sanfrancisco.conf 12345 142.250.190.110/32
...
**************************************************
LISTENING ON VPN: 167.99.163.123:12345/tcp
**************************************************
 try connecting remotely with a command like:
nc -v 167.99.163.123 12345
 or better yet (socat is a superior tool!):
socat TCP:167.99.163.123:12345 -
 and then on either end, you can type stuff in and
  hit enter. you should see it echoed on both ends
  like a chat.
**************************************************
+ eval socat TCP-LISTEN:12345,reuseaddr,keepalive,fork,range=142.250.190.110/32 -
++ socat TCP-LISTEN:12345,reuseaddr,keepalive,fork,range=142.250.190.110/32 -
hey
hows it going
```

then, in another term:

```
$ socat TCP:167.99.163.123:12345 -
hey
hows it going
```

## tips
kill the container if it hangs:
```
docker kill wireguard-port-test
```
