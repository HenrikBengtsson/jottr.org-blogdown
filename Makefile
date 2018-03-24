WEBSITE=https://clever-bassi-b11156.netlify.com
WEBSITE_PATH=jotternotes.com:public_html/jottr.org

check_links:
	wget --spider -o wget.log -e robots=off -w 1 -r -p $(WEBSITE)/index.html
	grep -B 2 '404' wget.log

deploy:
	@echo WEBSITE_PATH=$(WEBSITE_PATH)
	rsync -avvz --exclude '*~' --perms --chmod=ugo+rx --progress public/ $(WEBSITE_PATH)/

