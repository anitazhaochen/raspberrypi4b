docker run -d --restart=always --net=host \
    -e "AKID=LTAI4Fv1LnTSLHr4mpzLK" \
    -e "AKSCT=vJecAiuU4CpoFgYLJBJ1BMZpEm" \
    -e "DOMAIN=yapi.enjoyms.com,www.enjoyms.com,enjoyms.com,nas.enjoyms.com,gitlab.enjoyms.com,aria.enjoyms.com" \
    -e "REDO=300" \
    -e "TTL=600" \
    -e "TIMEZONE=8.0" \
    -e "TYPE=A,AAAA" \
    sanjusss/aliyun-ddns
