#!/bin/bash
# opensource@wandisco.com
 
echo WANdisco Subversion Installer for CentOS 6
echo Please report bugs or feature suggestions to opensource@wandisco.com
echo 
echo Gathering some information about your system...

MINVERSION='2'
SVNVER='1.7.7'
NOW=$(date +"%b-%d-%y%s")

#functions

gather_info () {
        ARCH=`uname -m`
        SVNSTATUS=`rpm -qa|grep ^subversion-[0-9]|awk 'BEGIN { FS = "-" } ; { print $1 }'`
}
check_tools () {
        COMMANDS="yum wget rpm"
        for C in $COMMANDS; do
                if [ -z "$(which $C)" ] ; then
                        echo "This installer uses the $C command which was not found in \$PATH."
                        exit 1
                fi
        done
}



check_centos_version ()
{
       if [ ! -e /etc/redhat-release ]; then
                echo "No /etc/redhat-release file, exiting"
                echo "You are most likely not using CentOS."
                echo "Installers for other operating systems are available from our downloads page:"
                echo "http://www.wandisco.com/subversion/download"
		echo "Exiting.."
                exit 1
        fi;
	cat /etc/redhat-release |grep -e 6.[0-9]
	if [ $? == 0 ]; then
		echo "CentOS version 6.x confirmed.."
	else
                echo "You are most likely using an incompatible version of CentOS."
		echo "This installer is made for CentOS 5.x"
                echo "Installers for other operating systems are available from our downloads page:"
                echo "http://www.wandisco.com/subversion/download"
                exit 1
	fi;
}


check_is_root ()
{
	if [[ $EUID -ne 0 ]]; then
   		echo "This script must be run as root" 1>&2
   		exit 1
	fi	
}
svn_remove_old ()
{
	if [ -f /etc/httpd/conf.d/subversion.conf ]; then
		echo Backing up /etc/httpd/conf.d/subversion.conf to /etc/httpd/conf.d/subversion.conf.backup-$NOW
		cp /etc/httpd/conf.d/subversion.conf /etc/httpd/subversion.conf.backup-$NOW
	fi
	echo Removing old packages...
	yum -y remove mod_dav_svn subversion subversion-devel subversion-perl subversion-python subversion-tools &>/dev/null
}
add_repo_config ()
{
        echo Adding repository configuration to /etc/yum.repos.d/
        if [ -f /etc/yum.repos.d/WANdisco-1.7.repo ]; then
		rm /etc/yum.repos.d/WANdisco-1.7.repo
	fi;
		echo " ------ Installing yum repo ------"
		echo "
[WANdisco]
name=WANdisco Repo
enabled=1
baseurl=http://opensource.wandisco.com/rhel/6/svn-1.7/RPMS/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-WANdisco
" > /etc/yum.repos.d/WANdisco-1.7.repo
		echo "Importing GPG key"
		wget http://opensource.wandisco.com/RPM-GPG-KEY-WANdisco -O /tmp/RPM-GPG-KEY-WANdisco &>/dev/null
		rpm --import /tmp/RPM-GPG-KEY-WANdisco
		rm -rf /tmp/RPM-GPG-KEY-WANdisco
		echo " ------ Installing yum repo: Done ------"	
}
install_svn ()
{
        echo Checking to see if you already have Subversion installed via rpm...
        if [[ "$SVNSTATUS" =~ subversion ]]; then
        	echo Subversion is already installed on the system.
        	echo Do you wish to replace the version of subversion currently installed with the WANdisco version? 
		echo This action will remove the previous version from your system 
		echo "[y/n]"
		read svn_install_confirm
		if [ "$svn_install_confirm" == "y" -o "$svn_install_confirm" == "Y" ]; then
			svn_remove_old
			add_repo_config
			echo		
			echo Installing Subversion $SVNVER
			echo
			yum -y install subversion.$ARCH subversion-perl.$ARCH subversion-python.$ARCH subversion-javahl.$ARCH subversion-tools.$ARCH
 			echo Would you like to install apache and the apache SVN modules?
			echo "[y/n]"
			read dav_svn_confirm
			if [ "$dav_svn_confirm" == "y" -o "$dav_svn_confirm" == "Y" ]; then
				echo Installing apache and subversion modules
				yum -y install mod_dav_svn.$ARCH httpd
				echo "Installation complete."
				echo "You can find the subversion configuration file for apache HTTPD at /etc/httpd/conf.d/subversion.conf"
				echo "By default, the modules are commented out in subversion.conf."
				echo "To enable the modules, please edit subversion.conf and remove the # infront of the LoadModule lines."
				echo "You should then restart httpd (/etc/init.d/httpd restart)"
			fi
			
	       	else
			echo "Install Cancelled"
			exit 1
		fi

	else
		# Install SVN
		echo "Subversion is not currently installed"
		echo "Starting installation, are you sure you wish to continue?"
		echo "[y/n]"
		read svn_install_confirm
                if [ "$svn_install_confirm" == "y" -o "$svn_install_confirm" == "Y" ]; then
			add_repo_config
                        echo
                        echo Installing Subversion $SVNVER
                        echo
			yum -y install subversion.$ARCH subversion-perl.$ARCH subversion-python.$ARCH subversion-tools.$ARCH
                        echo Would you like to install apache HTTPD and the apache SVN modules?
			echo "[y/n]"
                        read dav_svn_confirm
                        if [ "$dav_svn_confirm" == "y" -o "$dav_svn_confirm" == "Y" ]; then
                                echo Installing apache and subversion modules
				yum -y install mod_dav_svn.$ARCH httpd
                                echo "Installation complete."
                                echo "You can find the subversion configuration file for apache HTTPD at /etc/httpd/conf.d/subversion.conf"
                                echo "By default, the modules are commented out in subversion.conf."
                                echo "To enable the modules, please edit subversion.conf and remove the # infront of the LoadModule lines."
                                echo "You should then restart httpd (/etc/init.d/httpd restart)"
                        fi

                else
                        echo "Install Cancelled"
                        exit 1
                fi
		
        fi
	
}

install_32 ()
{
        echo Installing for $ARCH
	install_svn
}
install_64 ()
{
        echo Installing for $ARCH
	install_svn
}

#Main
check_is_root
check_centos_version
check_tools
gather_info

echo Checking your system arch
if [ "$ARCH" == "i686" -o "$ARCH" == "i386" ]; then
	if [ "$ARCH" == "i686" ]; then
		ARCH="i686"
	fi;
	install_32
elif [ "$ARCH" == "x86_64" ];
then
	install_64
else 
	echo Unsupported platform: $ARCH
	exit 1
fi
