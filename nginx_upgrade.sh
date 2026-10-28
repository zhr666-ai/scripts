#! /bin/bash
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m' # No Color 重置
YELLOW='\033[1;33m'

#新版本编译好的二进制文件路径
new_sbin='/usr/local/src/nginx-1.31.8/objs/nginx'
#旧版本备份后缀
old_last=$(date +%Y-%m-%d_%H%M%S)
#nginx路径
nginx_dir='/usr/local/nginx'
#master进程文件
pidfile="${nginx_dir}/logs/nginx.pid"
#旧master进程文件
pid_oldbin="${nginx_dir}/logs/nginx.pid.oldbin"


echo -e "${GREEN}-----正在执行nginx版本升级,使用前请确保新版nginx二进制编译完成-----${NC}"
if [ ! -f "${new_sbin}" ];then
    echo -e "${RED}新版本二进制 ${new_sbin} 不存在！${NC}"
    exit 1
fi
sleep 2
echo -e "${GREEN}查看当前nginx版本${NC}"
"${nginx_dir}/sbin/nginx" -V
sleep 2
#检查主进程文件是否存在
if [ ! -f "${pidfile}" ];then  
    echo -e "${RED}pid文件不存在，nginx未运行${NC}"
    exit 1
fi 
  

#平滑升级主函数
main_upgrade(){
       #向旧master发送USR2，拉起新版本
       kill -USR2 $(cat "${pidfile}")
       if [ $? -ne 0 ];then
           echo -e "${RED}拉取失败${NC}"
           exit 1
       fi
       #查看进程
       sleep 5
       echo -e "${GREEN}查看进程，确认是否有两个master${NC}"
       read -p "是否有两个master y/n：" check_master
       while true
       do
           if [ "$check_master" != 'n' && "$check_master" != 'y' ];then
               read -p "请输入正确选项y/n：" check_master
            else
                   break
            fi
        done
        if [ "$check_master" = 'y' ];then
               #给旧master发送WINCH，慢慢关闭旧worker
               echo -e "${GREEN}给旧master发送WINCH，慢慢关闭旧worker${NC}"
               kill -WINCH $(cat "${pid_oldbin}")
               if [ $? -ne 0 ];then
                  echo -e "${RED}kill WINCH执行失败${NC}"
                  exit 1
                else 
                     echo -e "${GREEN}kill WINCH执行成功${NC}"
               fi
               sleep 60
               #旧master优雅退出
               echo -e "${GREEN}旧master正在优雅退出${NC}"
               kill -QUIT $(cat "${pid_oldbin}")
               if [ $? -ne 0 ];then
                  echo -e  "${RED}kill QUIT执行失败${NC}"
                  exit 1
                else
                    echo -e "${GREEN}kill QUIT执行成功${NC}"
                fi
        else
            echo -e "${RED}未出现双master进程${NC}"
            exit 1
        fi
}

#检查旧版二进制文件是否存在
old_sbin="${nginx_dir}/sbin/nginx"

if [ ! -f "${old_sbin}" ];then
      echo -e "${RED}旧版nginx二进制文件不存在${NC}"
      exit 1
else
    echo -e "${GREEN}旧版二进制文件存在${NC}"
fi

#备份旧的nginx文件
echo -e "${GREEN}正在备份旧版二进制文件${NC}"
cp "${nginx_dir}/sbin/nginx" "${nginx_dir}/sbin/nginx.${old_last}"

if [ $? -eq 0 ];then
    echo -e "${GREEN}备份成功${NC}"
else 
     echo -e "${RED}旧版备份失败${NC}"
     exit 1
fi

#替换二进制文件
cp "${new_sbin}" "${nginx_dir}/sbin/nginx"
if [ $? -ne 0 ];then
    echo -e "${YELLOW}文件可能繁忙${NC}"
    echo -e "${GREEN}先将新版二进制文件以nginx.new复制过去${NC}"
    cp "${new_sbin}" "${nginx_dir}/sbin/nginx.new"
    echo -e "${GREEN}检查新版二进制文件nginx.new是否成功执行${NC}"
    "${nginx_dir}/sbin/nginx.new" -t
    if [ $? -eq 0 ];then
          echo -e "${GREEN}成功${NC}"
    else
        echo -e "${RED}失败${NC}"
        exit 1
    fi     
    echo -e "${GREEN}旧版二进制文件nginx改为nginx.old${NC}"
    mv "${nginx_dir}/sbin/nginx" "${nginx_dir}/sbin/nginx.old"

    echo -e "${GREEN}再将新版nginx.new改为nginx${NC}"
    mv "${nginx_dir}/sbin/nginx.new" "${nginx_dir}/sbin/nginx"
    main_upgrade

else
    echo -e "${GREEN}检查新版二进制文件nginx是否成功执行${NC}"
    "${nginx_dir}/sbin/nginx" -t
    if [ $? -eq 0 ];then
          echo -e "${GREEN}成功${NC}"
    else
        echo -e "${RED}失败${NC}"
        exit 1
    fi
    main_upgrade
fi
    
echo -e "${GREEN}脚本执行完毕，请查看新版本nginx${NC}"
"${nginx_dir}/sbin/nginx" -V