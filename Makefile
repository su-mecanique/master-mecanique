# Important directories
EXCEL_DIR = fiches-ue
WEBSITE_ROOT = ue-list-website
ROOT = $(WEBSITE_ROOT)/content
STATIC = $(WEBSITE_ROOT)/static
CONTENT = $(ROOT)/page
FIGURES = $(CONTENT)/figures

#-------------------------------------------------------------------------------------------

# Variables that generate files from UE xlsx references
UE_TEMPLATE = ue_template.jinja2
UE_FILES = $(wildcard $(EXCEL_DIR)/*.xlsx)
UE_MARKDOWN = $(patsubst %.xlsx,%.md,$(subst $(EXCEL_DIR),$(CONTENT),$(UE_FILES)))
UE_PDF = $(patsubst %.xlsx,%.pdf,$(subst $(EXCEL_DIR),$(STATIC),$(UE_FILES)))

# Tags database
TAG_FILE = tags.json

#-------------------------------------------------------------------------------------------

# Index page
INDEX_TEMPLATE = index_template.jinja2
INDEX_MARKDOWN = $(ROOT)/_index.md

# Evaluations page
MCC_TEMPLATE = mcc_template.jinja2
MCC_MARKDOWN = $(ROOT)/mcc.md

#-------------------------------------------------------------------------------------------

# Variables for html generation
HUGO = hugo
THEME = $(WEBSITE_ROOT)/themes/hugo-xmin
THEME_PATCH = theme.patch
INDEX_HTML = $(WEBSITE_ROOT)/html/index.html

# Variables for pdf generation
PDF_FLAGS = --resource-path=$(FIGURES) \
	-V classoption:DIV=13 \
	-V classoption:a4paper \
	-V documentclass:scrartcl

#-------------------------------------------------------------------------------------------

.PHONY: clean markdown pdf html

# Shorthand targets
all: html pdf markdown
html: $(INDEX_HTML)
markdown: $(UE_MARKDOWN) $(INDEX_MARKDOWN) $(MCC_MARKDOWN)
pdf: $(UE_PDF) $(STATIC)/catalog.pdf


clean:
	rm -rf $(dir $(CONTENT))
	rm -rf $(dir $(INDEX_HTML))
	rm -rf $(STATIC)/*


# Necessary folders
$(CONTENT):
	mkdir -p $(CONTENT)
$(STATIC):
	mkdir -p $(STATIC)


# Make individual UE markdown files
$(CONTENT)/%.md: $(EXCEL_DIR)/%.xlsx $(UE_TEMPLATE) $(CONTENT) $(TAG_FILE)
	./xlsx2md --output-dir $(CONTENT) --template $(UE_TEMPLATE) --tags $(TAG_FILE) $<

# Make index page
$(INDEX_MARKDOWN): $(UE_FILES) $(INDEX_TEMPLATE) $(TAG_FILE)
	./mkindex -o $@ -t $(INDEX_TEMPLATE) --tags $(TAG_FILE) $(UE_FILES)

# Make MCC page
$(MCC_MARKDOWN): $(UE_FILES) $(MCC_TEMPLATE) $(TAG_FILE)
	./mkindex -o $@ -t $(MCC_TEMPLATE) --tags $(TAG_FILE) $(UE_FILES)


# Generate html website
$(INDEX_HTML): markdown head_custom.html $(UE_PDF) $(STATIC)/catalog.pdf
	cp head_custom.html $(THEME)/layouts/partials/head_custom.html
	$(HUGO) --forceSyncStatic -s $(WEBSITE_ROOT) -d html


# Make individual pdf files
$(STATIC)/%.pdf: $(CONTENT)/%.md $(STATIC)
	pandoc $(PDF_FLAGS) -o $@ $<

# Compile to a single pdf
$(STATIC)/catalog.pdf: $(UE_PDF)
	pdftk $(UE_PDF) cat output $@
