# Important directories
EXCEL_DIR = fiches-ue/fiches
WEBSITE_ROOT = ue-list-website
ROOT = $(WEBSITE_ROOT)/content
STATIC = $(WEBSITE_ROOT)/static
CONTENT = $(ROOT)/page
FIGURES = $(CONTENT)/figures

#-------------------------------------------------------------------------------------------

# Variables that generate files from UE xlsx references
UE_TEMPLATE = templates/ue_template.jinja2
TEMPLATE_SHA1 = 8451e35efe7632bd1888ce9ce2f4713a4f8159ad
# Filter out all files identical to template
UE_FILES = $(shell sha1sum $(EXCEL_DIR)/U*.xlsx | grep -v $(TEMPLATE_SHA1) | awk '{print $$2}')
UE_MARKDOWN = $(patsubst %.xlsx,%.md,$(subst $(EXCEL_DIR),$(CONTENT),$(UE_FILES)))
UE_PDF = $(patsubst %.xlsx,%.pdf,$(subst $(EXCEL_DIR),$(STATIC),$(UE_FILES)))

# Tags database
TAG_FILE = tags.toml
LIST_UE = listes_ue.toml

#-------------------------------------------------------------------------------------------

# Variables for html generation
HUGO = hugo
THEME = $(WEBSITE_ROOT)/themes/hugo-xmin
THEME_PATCH = theme.patch
INDEX_HTML = $(WEBSITE_ROOT)/html/index.html

# Variables for pdf generation
PDF_VARIABLES = pandoc_variables.yml
PDF_FLAGS = --resource-path=$(FIGURES) \
	-V classoption:DIV=13 \
	-V classoption:a4paper \
	-V documentclass:scrartcl \
	--pdf-engine xelatex \
	--defaults $(PDF_VARIABLES)

#-------------------------------------------------------------------------------------------

.PHONY: clean markdown pdf html serve

# Shorthand targets
all: html pdf markdown
html: $(INDEX_HTML)
markdown: $(UE_MARKDOWN) $(ROOT)/_index.md $(ROOT)/mcc.md $(ROOT)/solides.md
pdf: $(UE_PDF) $(STATIC)/catalog.pdf


clean:
	rm -rf $(dir $(CONTENT))
	rm -rf $(dir $(INDEX_HTML))
	rm -rf $(STATIC)/*


# Necessary folders
$(CONTENT):
	mkdir -p $(CONTENT)
	mkdir -p $(CONTENT)/figures
$(STATIC):
	mkdir -p $(STATIC)


# Make individual UE markdown files
$(CONTENT)/%.md: $(EXCEL_DIR)/%.xlsx $(UE_TEMPLATE) $(CONTENT) $(TAG_FILE) $(LIST_UE)
	./xlsx2md \
		--output-dir $(CONTENT) \
		--template $(UE_TEMPLATE) \
		--tags $(TAG_FILE) --list-ue $(LIST_UE) $<

# Generic rule to make index pages
$(ROOT)/%.md: templates/%.jinja2 $(UE_FILES) $(TAG_FILE) $(LIST_UE) mkindex
	./mkindex -o $@ -t $< --tags $(TAG_FILE) --list-ue $(LIST_UE) $(UE_FILES)

# Generate html website
$(INDEX_HTML): markdown head_custom.html $(UE_PDF) $(STATIC)/catalog.pdf
	mkdir -p $(THEME)/layouts/partials
	cp head_custom.html $(THEME)/layouts/partials/head_custom.html
	$(HUGO) --forceSyncStatic -s $(WEBSITE_ROOT) -d html


# Make individual pdf files
$(STATIC)/%.pdf: $(CONTENT)/%.md $(STATIC) $(PDF_VARIABLES)
	pandoc $(PDF_FLAGS) -o $@ $<

# Compile to a single pdf
$(STATIC)/catalog.pdf: $(UE_PDF)
	pdftk $(UE_PDF) cat output $@


# Launch server
serve:
	hugo -s ue-list-website --forceSyncStatic -D server
