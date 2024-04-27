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

#rm -rf feeds/packages/lang/golang 
#git clone https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang
rm -rf ./feeds/luci/applications/luci-app-passwall

curl -sfL https://github.com/immortalwrt/luci/raw/master/modules/luci-base/root/usr/share/luci/menu.d/luci-base.json > feeds/luci/modules/luci-base/root/usr/share/luci/menu.d/luci-base.json

git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth 1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config
git clone --depth 1 https://github.com/xiaorouji/openwrt-passwall-packages package/openwrt-passwall-packages
git clone --depth 1 https://github.com/fw876/helloworld package/helloworld
git clone --depth 1 https://github.com/chenmozhijin/luci-app-adguardhome package/luci-app-adguardhome
svn_export "main" "luci-app-passwall" "package/luci-app-passwall" "https://github.com/xiaorouji/openwrt-passwall"

# hwnat
curl -sfL https://github.com/padavanonly/openwrt/raw/master/target/linux/ramips/dts/mt7621_xiaomi_mi-router-3g.dts > /target/linux/ramips/dts/mt7621_xiaomi_mi-router-3g.dts
curl -sfL https://github.com/padavanonly/openwrt/raw/master/target/linux/ramips/mt7621/base-files/etc/board.d/02_network > /target/linux/ramips/mt7621/base-files/etc/board.d/02_network

# turboacc 补丁
curl -sSL https://raw.githubusercontent.com/chenmozhijin/turboacc/luci/add_turboacc.sh -o add_turboacc.sh && bash add_turboacc.sh

# 安装插件
./scripts/feeds update -l
./scripts/feeds install -a

# 调整菜单位置
sed -i "s|services|system|g" feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i "s|services|network|g" feeds/luci/applications/luci-app-nlbwmon/root/usr/share/luci/menu.d/luci-app-nlbwmon.json
# 个性化设置
sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate
sed -i 's/OpenWrt/MI-R3G/' package/base-files/files/bin/config_generate
# DNS劫持
sed -i '/dns_redirect/d' package/network/services/dnsmasq/files/dhcp.conf
# 汉化
cd package
curl -sfL -o ./convert_translation.sh https://github.com/kenzok8/small-package/raw/main/.github/diy/convert_translation.sh
chmod +x ./convert_translation.sh && bash ./convert_translation.sh
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
