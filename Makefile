ROOT = ue-list-website/content
CONTENT = $(ROOT)/page
EXCEL_DIR = src

UE_TEMPLATE = ue_template.jinja2
UE_FILES = $(wildcard $(EXCEL_DIR)/*.xlsx)
UE_MARKDOWN = $(patsubst %.xlsx,%.md,$(subst $(EXCEL_DIR),$(CONTENT),$(UE_FILES)))

INDEX_TEMPLATE = index_template.jinja2
TAG_FILE = tags.json

.PHONY: clean

all: $(UE_MARKDOWN) $(ROOT)/index.md

clean:
	rm -rf $(dir $(CONTENT))

$(CONTENT):
	mkdir -p $(CONTENT)

$(CONTENT)/%.md: $(EXCEL_DIR)/%.xlsx $(UE_TEMPLATE) $(CONTENT) $(TAG_FILE)
	./xlsx2md --output-dir $(CONTENT) --template $(UE_TEMPLATE) --tags $(TAG_FILE) $<

$(ROOT)/index.md: $(UE_FILES) $(INDEX_TEMPLATE) $(TAG_FILE)
	./mkindex -o $@ -t $(INDEX_TEMPLATE) --tags $(TAG_FILE) $(UE_FILES)
