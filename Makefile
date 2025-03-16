WEBSITE_ROOT = ue-list-website
ROOT = $(WEBSITE_ROOT)/content
STATIC = $(WEBSITE_ROOT)/static
CONTENT = $(ROOT)/page
EXCEL_DIR = fiches-ue

UE_TEMPLATE = ue_template.jinja2
UE_FILES = $(wildcard $(EXCEL_DIR)/*.xlsx)
UE_MARKDOWN = $(patsubst %.xlsx,%.md,$(subst $(EXCEL_DIR),$(CONTENT),$(UE_FILES)))
UE_PDF = $(patsubst %.xlsx,%.pdf,$(subst $(EXCEL_DIR),$(STATIC),$(UE_FILES)))

INDEX_TEMPLATE = index_template.jinja2
INDEX_MARKDOWN = $(ROOT)/_index.md
TAG_FILE = tags.json

HUGO = hugo
THEME = $(WEBSITE_ROOT)/themes/hugo-xmin
THEME_PATCH = theme.patch
INDEX_HTML = $(WEBSITE_ROOT)/html/index.html
FIGURES = $(CONTENT)/figures

PDF_FLAGS = --resource-path=$(FIGURES) \
	-V classoption:DIV=13 \
	-V classoption:a4paper \
	-V documentclass:scrartcl


.PHONY: clean markdown pdf

all: $(INDEX_HTML) $(UE_MARKDOWN) $(INDEX_MARKDOWN) $(UE_PDF)

markdown: $(UE_MARKDOWN) $(INDEX_MARKDOWN)

pdf: $(UE_PDF) $(STATIC)/catalog.pdf

clean:
	rm -rf $(dir $(CONTENT))
	rm -rf $(dir $(INDEX_HTML))
	rm -rf $(STATIC)/*

$(CONTENT):
	mkdir -p $(CONTENT)

$(CONTENT)/%.md: $(EXCEL_DIR)/%.xlsx $(UE_TEMPLATE) $(CONTENT) $(TAG_FILE)
	./xlsx2md --output-dir $(CONTENT) --template $(UE_TEMPLATE) --tags $(TAG_FILE) $<

$(INDEX_MARKDOWN): $(UE_FILES) $(INDEX_TEMPLATE) $(TAG_FILE)
	./mkindex -o $@ -t $(INDEX_TEMPLATE) --tags $(TAG_FILE) $(UE_FILES)

$(INDEX_HTML): $(UE_MARKDOWN) $(INDEX_MARKDOWN) head_custom.html $(UE_PDF) $(STATIC)/catalog.pdf
	cp head_custom.html $(THEME)/layouts/partials/head_custom.html
	$(HUGO) --forceSyncStatic -s $(WEBSITE_ROOT) -d html

$(STATIC):
	mkdir -p $@

$(STATIC)/%.pdf: $(CONTENT)/%.md $(STATIC)
	pandoc $(PDF_FLAGS) -o $@ $<

$(STATIC)/catalog.pdf: $(UE_PDF)
	pdftk $(UE_PDF) cat output $@
