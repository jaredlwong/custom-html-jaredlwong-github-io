rvm:
	rvm gemset use jaredlwong

install:
	bundle install

build:
	DEV=1 jekyll build

serve:
	DEV=1 jekyll serve --drafts

upload:
	rsync --recursive --delete --verbose _site/ mit:~/Public

clean:
	rm -r _site
