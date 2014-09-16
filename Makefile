rvm:
	rvm gemset use jaredlwong

install:
	bundle install

build:
	jekyll build --drafts

serve:
	jekyll serve --drafts

upload:
	rsync --recursive --delete --verbose _site/ mit:~/Public

clean:
	rm -r _site
