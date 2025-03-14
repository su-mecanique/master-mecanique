ROOT = ue-list-website/content
CONTENT = $(ROOT)/page
EXCEL_DIR = src

UE_TEMPLATE = ue_template.jinja2
UE_FILES = $(wildcard $(EXCEL_DIR)/*.xlsx)
UE_MARKDOWN = $(patsubst %.xlsx,%.md,$(subst $(EXCEL_DIR),$(CONTENT),$(UE_FILES)))
UE_PDF = $(patsubst %.xlsx,%.pdf,$(subst $(EXCEL_DIR),$(CONTENT),$(UE_FILES)))

INDEX_TEMPLATE = index_template.jinja2
INDEX_MARKDOWN = $(ROOT)/_index.md
TAG_FILE = tags.json

HUGO = hugo
WEBSITE_ROOT = ue-list-website
THEME = $(WEBSITE_ROOT)/themes/hugo-xmin
THEME_PATCH = theme.patch
INDEX_HTML = $(WEBSITE_ROOT)/html/index.html
FIGURES = $(CONTENT)/figures

PDF_FLAGS = --resource-path=$(FIGURES) \
	-V classoption:DIV=13 \
	-V fontfamily:libertinus \
	-V classoption:a4paper \
	-V documentclass:scrartcl


.PHONY: clean markdown pdf

all: $(INDEX_HTML) $(UE_MARKDOWN) $(INDEX_MARKDOWN) $(UE_PDF)

markdown: $(UE_MARKDOWN) $(INDEX_MARKDOWN)

pdf: $(UE_PDF)

clean:
	rm -rf $(dir $(CONTENT))
	rm -rf $(dir $(INDEX_HTML))

$(CONTENT):
	mkdir -p $(CONTENT)

$(CONTENT)/%.md: $(EXCEL_DIR)/%.xlsx $(UE_TEMPLATE) $(CONTENT) $(TAG_FILE)
	./xlsx2md --output-dir $(CONTENT) --template $(UE_TEMPLATE) --tags $(TAG_FILE) $<

$(INDEX_MARKDOWN): $(UE_FILES) $(INDEX_TEMPLATE) $(TAG_FILE)
	./mkindex -o $@ -t $(INDEX_TEMPLATE) --tags $(TAG_FILE) $(UE_FILES)

$(INDEX_HTML): $(UE_MARKDOWN) $(INDEX_MARKDOWN) head_custom.html
	cp head_custom.html $(THEME)/layouts/partials/head_custom.html
	$(HUGO) -s $(WEBSITE_ROOT) -d html

$(CONTENT)/%.pdf: $(CONTENT)/%.md
	pandoc $(PDF_FLAGS) -o $@ $<
