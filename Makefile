WEBSITE=http://www.jottr.org

serve:
	Rscript -e "blogdown::serve_site()" &

check_links:
	wget --spider -o wget.log -e robots=off -w 1 -r -p $(WEBSITE)/index.html
	grep -B 2 '404' wget.log

