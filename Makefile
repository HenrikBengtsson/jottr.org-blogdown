WEBSITE_PATH=jotternotes.com:public_html/jottr.org/

deploy:
	@echo WEBSITE_PATH=$(WEBSITE_PATH)
	rsync -avvz --exclude '*~' --perms --chmod=ugo+rx --progress public/ $(WEBSITE_PATH)/

