#！/bin/bash
#sys_collect.sh -系统运行状态￥基础信息采集脚本
#采集结果输出到./sys_info_YYYYMMDD_HHMMSS.log中

#输出文件定义
Log_file="./sys_info_$(date +%Y%m%d_%H%M%S).log"

#写入头部
cat > ${Log_file} <<EOF
"========================================================"
系统信息采集报告
采集时间：$(date "+%Y-%m-%d %H:%M:%S")
主机名：$(hostname)
采集脚本：$0
"========================================================"
EOF

#1.基础系统信息
echo -e "\n[1.基础系统信息]" >> ${Log_file}
echo "主机名：$(hostname)" >> ${Log_file}
echo "内核版本：$(uname -r)" >> ${Log_file}
echo "系统版本：$(cat /etc/os-release | grep PRETTY_NAME | awk -F '"' '{print $2}' )" >> ${Log_file}
echo "架构：$(uname -m)" >> ${Log_file}
echo "uptime：$(uptime)" >> ${Log_file}
echo "当前登录用户：$(whoami)" >> ${Log_file}

#2.CPU,内存负载
echo -e "\n[2.CPU & 内存负载]" >> ${Log_file}
echo "top -bn1摘要：" >> ${Log_file}
top -bn1 | head -15 >> ${Log_file}
echo -e "\n free内存：" c
free -h >> ${Log_file}


#3.磁盘信息
echo -e "\n [磁盘挂载&使用率]" >> ${Log_file}
df -h >> ${Log_file}
lsblk >> ${Log_file}

#4.进程信息
echo -e "\n[高占用进程]" >> ${Log_file}
echo "CPU TOP10:" >> ${Log_file}
ps -ef --sort=-%cpu | head 11 >> ${Log_file}
echo -e "\nMEM TOP10:" >> ${Log_file}
ps -ef --sort=-%mem | head 11c

#5.防火墙状态
echo -e "\n[5.防火墙状态]" >> ${Log_file}
if command -v systemctl &>/dev/null;then
    systemctl status firewalld 2>/dev/null || echo "firewalld not found"
    systemctl status ufw 2>/dev/null || echo "ufw not found"
fi >> ${Log_file}

echo -e "\n========================================================"
echo "采集完成，请到文件${Log_file}中查看"
echo "脚本执行完毕"