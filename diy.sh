#!/bin/bash
svn_export() {
	# 参数1是分支名, 参数2是子目录, 参数3是目标目录, 参数4仓库地址
 	echo -e "clone $4/$2 to $3"
	TMP_DIR="$(mktemp -d)" || exit 1
 	ORI_DIR="$PWD"
	[ -d "$3" ] || mkdir -p "$3"
	TGT_DIR="$(cd "$3"; pwd)"
	git clone --depth 1 -b "$1" "$4" "$TMP_DIR" >/dev/null 2>&1 && \
	cd "$TMP_DIR/$2" && rm -rf .git >/dev/null 2>&1 && \
	cp -af . "$TGT_DIR/" && cd "$ORI_DIR"
	rm -rf "$TMP_DIR"
}

rm -rf ./feeds/packages/lang/golang 
git clone https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang
rm -rf ./feeds/luci/applications/luci-app-passwall
rm -rf ./feeds/luci/applications/luci-app-filebrowser
rm -rf ./feeds/luci/applications/luci-app-ssr-*
rm -rf ./feeds/luci/applications/luci-app-smartdns
rm -rf ./feeds/luci/applications/luci-app-argon-config
rm -rf ./feeds/luci/themes/luci-theme-argon
rm -rf ./feeds/luci/applications/luci-app-alist
rm -rf ./feeds/packages/net/alist
rm -rf ./feeds/packages/net/smartdns
rm -rf ./feeds/packages/net/xray-core

git clone --depth 1 https://github.com/pymumu/luci-app-smartdns package/luci-app-smartdns
git clone --depth 1 https://github.com/pymumu/openwrt-smartdns package/smartdns
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth 1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config
git clone --depth 1 https://github.com/xiaorouji/openwrt-passwall-packages package/openwrt-passwall-packages
git clone --depth 1 https://github.com/fw876/helloworld package/helloworld
git clone --depth 1 https://github.com/sbwml/luci-app-alist package/luci-app-alist
git clone --depth 1 https://github.com/chenmozhijin/luci-app-adguardhome package/luci-app-adguardhome
git clone --depth 1 https://github.com/OldCoding/luci-app-filebrowser package/luci-app-filebrowser
git clone --depth 1 https://github.com/hudra0/luci-app-qosmate package/luci-app-qosmate
git clone --depth 1 https://github.com/hudra0/qosmate package/qosmate
svn_export "main" "luci-app-passwall" "package/luci-app-passwall" "https://github.com/xiaorouji/openwrt-passwall"
svn_export "main" "luci-app-alist" "feeds/luci/applications/luci-app-alist" "https://github.com/sbwml/luci-app-alist"
svn_export "main" "alist" "feeds/packages/net/alist" "https://github.com/sbwml/luci-app-alist"

# turboacc 补丁
curl -sSL https://raw.githubusercontent.com/chenmozhijin/turboacc/luci/add_turboacc.sh -o add_turboacc.sh && bash add_turboacc.sh

# 安装插件
./scripts/feeds update -i
./scripts/feeds install -a

# 个性化设置
sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/MI-R3G/' package/base-files/files/bin/config_generate
# DNS劫持
sed -i '/dns_redirect/d' package/network/services/dnsmasq/files/dhcp.conf
sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=1\.8/" package/luci-app-adguardhome/Makefile
cd package
# 汉化
curl -sfL -o ./convert_translation.sh https://github.com/kenzok8/small-package/raw/main/.github/diy/convert_translation.sh
chmod +x ./convert_translation.sh && bash -v ./convert_translation.sh
# 更新passwall规则
curl -sfL -o ./luci-app-passwall/root/usr/share/passwall/rules/gfwlist https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/gfw.txt

# AdguardHome核心
cd ./luci-app-adguardhome/root/usr
mkdir -p ./bin/AdGuardHome && cd ./bin/AdGuardHome
ADG_VER=$(curl -sfL https://api.github.com/repos/AdguardTeam/AdGuardHome/releases 2>/dev/null | grep 'tag_name' | egrep -o "v[0-9].+[0-9.]" | awk 'NR==1')
curl -sfL -o /tmp/AdGuardHome_linux.tar.gz https://github.com/AdguardTeam/AdGuardHome/releases/download/${ADG_VER}/AdGuardHome_linux_mipsle_softfloat.tar.gz
tar -zxf /tmp/*.tar.gz -C /tmp/ && chmod +x /tmp/AdGuardHome/AdGuardHome
upx_latest_ver="$(curl -sfL https://api.github.com/repos/upx/upx/releases/latest 2>/dev/null | egrep 'tag_name' | egrep '[0-9.]+' -o 2>/dev/null)"
curl -sfL -o /tmp/upx-${upx_latest_ver}-amd64_linux.tar.xz "https://github.com/upx/upx/releases/download/v${upx_latest_ver}/upx-${upx_latest_ver}-amd64_linux.tar.xz"
xz -d -c /tmp/upx-${upx_latest_ver}-amd64_linux.tar.xz | tar -x -C "/tmp"
/tmp/upx-${upx_latest_ver}-amd64_linux/upx --ultra-brute /tmp/AdGuardHome/AdGuardHome > /dev/null 2>&1
mv /tmp/AdGuardHome/AdGuardHome ./ && rm -rf /tmp/AdGuardHome
