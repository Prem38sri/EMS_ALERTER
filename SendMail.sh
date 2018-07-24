(
  echo To: to_list@company.com,to_list1@company.com
  echo Cc: cc_list@company.com
  echo From: EAI_ADMIN
  echo "Content-Type: text/html; "
  echo Subject: $1
  echo
  cat /{INSTALL_HOME}/tmp/report.html
) | /usr/sbin/sendmail -t
