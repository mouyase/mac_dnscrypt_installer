#!/bin/bash
#Based from https://github.com/felixonmars/dnsmasq-china-list/blob/master/install.sh


echo "Setting hosts..."

sudo sh -c 'sync && echo "199.232.4.133 raw.githubusercontent.com">>/etc/hosts'
sudo sh -c 'sync && echo "199.232.4.133 raw.github.com">>/etc/hosts'

brew install dnsmasq

brew install dnscrypt-proxy

sudo cp -f dnsmasq.conf /usr/local/etc/dnsmasq.conf

sudo cp -f dnscrypt-proxy.toml /usr/local/etc/dnscrypt-proxy.toml

sudo rm -rf /usr/local/etc/dnsmasq.d

sudo mkdir /usr/local/etc/dnsmasq.d

WORKDIR="$(mktemp -d)"
SERVERS=(114.114.114.114)

CONF_WITH_SERVERS=(accelerated-domains.china google.china apple.china)
CONF_SIMPLE=(bogus-nxdomain.china)

echo "Downloading latest configurations..."
git clone --depth=1 https://gitee.com/felixonmars/dnsmasq-china-list.git "$WORKDIR"

echo "Removing old configurations..."
for _conf in "${CONF_WITH_SERVERS[@]}" "${CONF_SIMPLE[@]}"; do
  sudo rm -f /usr/local/etc/dnsmasq.d/"$_conf"*.conf
done

echo "Installing new configurations..."
for _conf in "${CONF_SIMPLE[@]}"; do
  sudo cp "$WORKDIR/$_conf.conf" "/usr/local/etc/dnsmasq.d/$_conf.conf"
done

for _server in "${SERVERS[@]}"; do
  for _conf in "${CONF_WITH_SERVERS[@]}"; do
    sudo cp "$WORKDIR/$_conf.conf" "/usr/local/etc/dnsmasq.d/$_conf.$_server.conf"
  done
  sudo sed -i "" "s|^\(server.*\)/[^/]*$|\1/$_server|" /usr/local/etc/dnsmasq.d/*."$_server".conf
done

curl https://raw.githubusercontent.com/googlehosts/hosts/master/hosts-files/dnsmasq.conf -o "$WORKDIR/google-hosts.conf"

sudo cp -f "$WORKDIR/google-hosts.conf" /usr/local/etc/dnsmasq.d/google-hosts.conf


echo "Restarting dnsmasq service..."
sudo brew services restart dnsmasq
echo "Restarting dnscrypt-proxy service..."
sudo brew services restart dnscrypt-proxy
echo "Flush dns..."
sudo killall -HUP mDNSResponder

echo "Cleaning hosts..."
sudo sed -i "" "s/199.232.4.133 raw.githubusercontent.com//g" /etc/hosts
sudo sed -i "" "s/199.232.4.133 raw.github.com//g" /etc/hosts

echo "Cleaning up..."
rm -rf "$WORKDIR"