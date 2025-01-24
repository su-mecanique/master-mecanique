# %%#
# need to install openpyxl
import pandas as pd
import yaml
import pypandoc
import glob
import os


def load_excel(
    filename: str, path: str = os.getcwd(), tab: int = 0, **kwargs
) -> pd.DataFrame:
    """Load a tab of an excel file."""
    if not os.path.isfile(os.path.join(path, filename)):
        raise OSError(f"File '{os.path.join(path, filename)}' not found.")

    df = pd.read_excel(
        os.path.join(path, filename),
        sheet_name=tab,
        engine="openpyxl",
        usecols=[0, 1, 2],
        **kwargs,
    )
    df = df.where(pd.notnull(df), None)
    # reverse rows and columns
    df = df.transpose()

    return df


# list all the files in the directory


# import excel file as a dataframe and convert it to a dictionary


def generate_markdown(ue_df: pd.DataFrame, out_file_name: str = None):
    ue_code = ue_df["code"]["value"]
    print(f"Generating markdown for {ue_code}")

    if not os.path.exists(out_dir_name):
        os.makedirs(out_dir_name)

    # Generate markdown file
    with open(f"{out_file_name}.md", "w") as file:
        file.write(
            f"# {ue_df['code']['value']} - {ue_df['title_fr']['value']} ({ue_df['title_en']['value']})   \n"
        )
        file.write("## Informations générales  \n")
        for field_name in [
            "title_en",
            "title_fr",
            "code",
            "resp_name",
            "resp_mail",
            "h_cm",
            "h_td",
            "h_tp",
            "h_pr",
            "ects",
            "semester",
            "period",
            "lang",
            "public",
            "where",
            #   "edt", put as a link (special case)
        ]:
            file.write(
                f" - {ue_df[field_name]['tag']} : {ue_df[field_name]['value']} \n"
            )
        file.write(
            f" - {ue_df['edt']['tag']} : [Link]({ue_df['edt']['value']}) \n"
        )

        file.write("  \n")
        file.write("## Informations pédagogiques  \n")
        for field_name in [
            "content_fr",
            "content_en",
            "keywords_fr",
            "keywords_en",
            "prereq_fr",
            "prereq_en",
        ]:
            file.write(
                f"\n - **{ue_df[field_name]['tag']}** : {ue_df[field_name]['value']} \n"
            )
        if ue_df["biblio"]["value"] is not None:
            file.write("\n - **Bibliographie** : \n")
            for line in ue_df["biblio"]["value"].split("\n"):
                file.write(f"   {line} \n")
        return f"{out_file_name}.md"
    
## 
src_files = glob.glob("src/U*")
for file_name in src_files:


# %%


src_files = glob.glob("src/U*")
list_ue = []
for file_name in src_files:
    print(f"Processing {file_name}")
    # Load the excel file
    ue_df = load_excel(file_name, comment="#", index_col=0)
    ue_code = ue_df["code"]["value"]
    out_dir_name = "out"
    out_file_name = f"{out_dir_name}/{ue_code}"

    # Generate markdown file
    md_file = generate_markdown(ue_df, out_file_name)

    # Convert markdown to yaml dict
    with open(f"{out_file_name}.yaml", "w") as file:
        yaml.dump(ue_df.to_dict(), file, encoding=("utf-8"))

    # Convert to pdf and html
    pdoc_args = ["-V", "geometry:margin=1.5cm", "--mathjax"]
    pypandoc.convert_file(
        f"{out_file_name}.md",
        "pdf",
        extra_args=pdoc_args,
        outputfile=f"{out_file_name}.pdf",
    )
    pypandoc.convert_file(
        f"{out_file_name}.md",
        "html",
        extra_args=pdoc_args,
        outputfile=f"{out_file_name}.html",
    )
    
    # add "pdf_file" in the dataframe
    ue_df.at["pdf_file", "value"] = f"{out_file_name}.pdf"
    ue_df.at["html_file", "value"] = f"{out_file_name}.html"
    ue_df.loc["md_file", "value"] = f"{out_file_name}.md"
    list_ue.append(ue_df)


# %%
# print a md file with all the links
with open(f"{out_dir_name}/index.md", "w") as file:
    file.write("# Liste des UE  \n")
    for ue_df in list_ue:
        file.write(
            f" - [{ue_df['code']['value']} - {ue_df['title_fr']['value']} ({ue_df['title_en']['value']})]({ue_df['code']['value']}.md)  \n"
        )

# %%
