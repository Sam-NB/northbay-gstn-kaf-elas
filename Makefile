### common definitions ###
DOCNAME = nb.gstn.kafka.elas
ZIPNAME = nb.gstn.kafka.elas
OPENER  = xdg-open

list:
	cat Makefile | grep "^[A-Za-z].*:" | awk '{print $$1}' | sed "s/://g" | sort

ts := $(shell /bin/date "+%Y.%m.%d.%H.%M.%S")
timestamp:
	 @echo Timestamp is $(ts)

### documentation ###
clean_doc:
	 rm -rf $(DOCNAME).html $(DOCNAME).pdf
clean_html:
	 rm -rf $(DOCNAME).html  
html: clean_html
	 pandoc -s -f markdown+hard_line_breaks -c style.css -o $(DOCNAME).html README.md
open_html: html
	 $(OPENER) $(DOCNAME).html
pdf: clean_doc html
	 wkhtmltopdf $(DOCNAME).html $(DOCNAME).pdf
open_pdf: pdf
	 $(OPENER) $(DOCNAME).pdf
web_deploy: html
	export AWS_PROFILE=571792806194_AdministratorAccess
	aws s3 cp nb.gstn.kafka.elas.html s3://northblog/
	aws s3 cp style.css s3://northblog/
	aws s3 sync images/ s3://northblog/images/  --delete
	
### main functions ###
zip:
	 git archive master --format zip --output $(ZIPNAME).$(ts).zip
clean: clean_doc
	 rm -rf dependencies
	 rm -rf $(ZIPNAME).*.zip
