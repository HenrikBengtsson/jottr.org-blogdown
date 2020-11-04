WEBSITE=https://www.jottr.org

start: hugo_version
	Rscript -e "cat(paste0('\nBlogdown PID: ',Sys.getpid(),'\n'))" -e "blogdown::serve_site()" &

hugo_version:
	@Rscript -e "cat(paste0(blogdown::hugo_version(),'\n'))"

check_links:
	wget --spider -o wget.log -e robots=off -w 1 -r -p $(WEBSITE)/index.html
	grep -B 2 '404' wget.log

spell/%: %
	Rscript -e "spelling::spell_check_files('$<', ignore=readLines('WORDLIST'))"

spell-202011: spell/content/post/2020-11-04-have-trust-in-the-future.md spell/content/post/2020-11-04-parallelly-and-future.md spell/content/post/2020-11-04-future_1.20.1.md

spelling: spell-202011
