CONTENT = content/page
EXCEL_DIR = src

TEMPLATE = ue_template.jinja2
UE_FILES = $(wildcard $(EXCEL_DIR)/*.xlsx)
UE_MARKDOWN = $(patsubst %.xlsx,%.md,$(subst $(EXCEL_DIR),$(CONTENT),$(UE_FILES)))

.PHONY: clean

all: $(UE_MARKDOWN)

clean:
	rm -rf $(dir $(CONTENT))

$(CONTENT):
	mkdir -p $(CONTENT)

$(CONTENT)/%.md: $(EXCEL_DIR)/%.xlsx $(TEMPLATE) $(CONTENT)
	./xlsx2md --output-dir $(CONTENT) --template $(TEMPLATE) $<
