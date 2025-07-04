# %%#
# need to install openpyxl
import pandas as pd
import yaml
import pypandoc
import glob
import os
import pathlib
import mimetypes
import jinja2
import shutil
import json
import sys
import tomllib
import logging
import warnings

from zipfile import ZipFile


logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.WARNING)


def access_nested(key, data):
    """Access dictionary with key.subkey.subsubkey"""
    keys = key.split(".")
    val = data

    for k in keys:
        val = val[k]
    return val


def collect_tags(ue_lists, keys, depth, max_depth):
    """Collect all keys in nested dictionary"""
    if depth == max_depth:
        return keys

    sub_keys = []
    for key in keys:
        node_data = access_nested(key, ue_lists)

        # If leaf_data is not a dict, we have a leaf
        if not isinstance(node_data, dict):
            sub_keys += [key]
        else:
            sub_keys += [key + "." + k for k in node_data.keys()]

    return collect_tags(ue_lists, sub_keys, depth + 1, max_depth)


def flatten(nodes, values):
    if len(nodes) == 0:
        return values

    sub_nodes = []
    for d in nodes:
        if isinstance(d, dict):
            sub_nodes += list(d.values())
        elif isinstance(d, list):
            values += d


    return flatten(sub_nodes, values)


def reverse_tags_ue(ue_lists, depth=0):
    """For a list of UE codes per track, return tracks per UE code"""
    all_tags = collect_tags(ue_lists, ue_lists.keys(), 0, depth)
    all_ue = {key: set() for key in set(flatten([ue_lists], []))}
    tag2list = {
        tag: flatten([access_nested(tag, ue_lists)], []) for tag in all_tags
    }

    for k, ue_list in tag2list.items():
        for ue in ue_list:
            all_ue[ue].add(k)

    return all_ue


def load_codes_ue(ue_list_file: str):
    "Load list of all UE codes"
    with open(ue_list_file, "rb") as fh:
        return reverse_tags_ue(tomllib.load(fh), 0)


def load_excel(
    filename: str, path: str = os.getcwd(), tab: int = 0, **kwargs
) -> pd.DataFrame:
    """Load a tab of an excel file."""
    with warnings.catch_warnings(action='ignore', category=UserWarning):
        df = pd.read_excel(
            filename,
            sheet_name=tab,
            engine="openpyxl",
            usecols=[0, 1, 3],
            **kwargs,
        )

    df = df.where(pd.notnull(df), None)
    # reverse rows and columns
    df = df.dropna().transpose()

    return df


def generate_markdown(ue_df: pd.DataFrame, out_dir_name: str, out_file_name: str = None):
    "import excel file as a dataframe and convert it to a dictionary"
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
        # add image if it is given
        if ue_df["image"]["value"] is not None:
            image_dir = f"{out_dir_name}/figures"
            if not os.path.exists(image_dir):
                os.makedirs(image_dir)
            # check that the image exists or trow a warning
            if not os.path.exists(f"src/figures/{ue_df['image']['value']}"):
                print(
                    f"Warning: image {ue_df['image']['value']} does not exist in src/figures"
                )
            # copy the image to the out directory
            os.system(f"cp src/figures/{ue_df['image']['value']} {image_dir}")
            file.write(f"   ![Figure](figures/{ue_df['image']['value']}) \n")
        return f"{out_file_name}.md"


def is_excel(path: pathlib.Path):
    "Check if path is an excel file"
    if not path.exists():
        return False

    mime = mimetypes.guess_type(path.absolute().as_uri())[0]
    return mime == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"


def render_markdown(template: jinja2.Template, info: dict, tag_file: str):
    "Render dict to a markdown file"
    with open(tag_file, "rb") as fh:
        TAGS = tomllib.load(fh)

    if (not "GENERIC_INFOS" in TAGS) or (not "PEDAGOGICAL_INFOS" in TAGS):
        print(f"{tag_file} is missing essential information", file=sys.stderr)
        sys.exit(1)

    GENERIC_INFOS = TAGS["GENERIC_INFOS"]
    PEDAGOGICAL_INFOS = TAGS["PEDAGOGICAL_INFOS"]

    info["GENERIC_INFOS"] = {k: v for k, v in info.items() if k in GENERIC_INFOS}
    info["PEDAGOGICAL_INFOS"] = {
        k: v for k, v, in info.items() if k in PEDAGOGICAL_INFOS
    }
    info["TAG_TITLES"] = TAGS["TAG_TITLES"]

    invalid_keys = [k for k in info.keys() if not isinstance(k, str)]

    if len(invalid_keys) != 0:
        if 'code' in info:
            logger.warning(f"{info['code']['value']} has invalid keys")

    # Filter out invalid keys
    info = {k: v for k, v in info.items() if isinstance(k, str)}
    return template.render(**info)


def extract_external_image(filename: pathlib.Path,
                           image_path: pathlib.Path,
                           output_dir: pathlib.Path):
    figure_dir = output_dir / 'figures'
    figure_dir.mkdir(exist_ok=True)

    figure = filename.parent / 'figures' / image_path
    shutil.copyfile(figure, figure_dir / image_path)
    return figure


def extract_excel_image(filename: pathlib.Path, output_dir: pathlib.Path):
    "Extract image embeded into an excel file"
    if not is_excel(filename):
        return

    fh = ZipFile(filename)
    media = [name for name in fh.namelist() if name.startswith('xl/media')]

    if len(media) == 0:
        return

    image = pathlib.Path(media[0])

    figure_dir = output_dir / 'figures'
    figure_dir.mkdir(exist_ok=True)

    figure = figure_dir / (filename.stem + image.suffix)
    extracted = fh.extract(str(image))
    os.rename(extracted, figure)

    mime = mimetypes.guess_type(figure.absolute().as_uri())[0]
    if mime not in ('image/png', 'image/svg+xml', 'image/jpeg'):
        return

    return figure


def main():
    "generate a list of UEs"
    src_files = glob.glob("src/U*.xlsx")
    list_ue = []
    for file_name in src_files:
        print(f"Processing {file_name}")
        # Load the excel file
        ue_df = load_excel(file_name, comment="#", index_col=0)
        ue_code = ue_df["code"]["value"]
        out_dir_name = "out"
        out_file_name = f"{out_dir_name}/{ue_code}"

        # Generate markdown file
        md_file = generate_markdown(ue_df, out_dir_name, out_file_name)

        # Convert markdown to yaml dict
        with open(f"{out_file_name}.yaml", "w") as file:
            yaml.dump(ue_df.to_dict(), file, encoding=("utf-8"))

        # Convert to pdf and html
        pdoc_args = [
            "-V",
            "geometry:margin=1.5cm",
            "--mathjax",
            "--resource-path=src",
        ]
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
        ue_df.loc["tag", "pdf_file"] = "Fichier PDF"
        ue_df.loc["value", "pdf_file"] = f"{out_file_name}.pdf"
        ue_df.loc["tag", "md_file"] = "Fichier MD"
        ue_df.loc["value", "md_file"] = f"{out_file_name}.md"
        list_ue.append(ue_df)

    # print a md file with all the links
    with open(f"README.md", "w") as file:
        print("Writing README.md")
        file.write("# Liste des UE  \n")
        for ue_df in list_ue:
            file.write(
                f" - [{ue_df['code']['value']} - {ue_df['title_fr']['value']} ({ue_df['title_en']['value']})]({ue_df['md_file']['value']}). Résp. {ue_df['resp_name']['value']}. {ue_df['content_en']['value']} \n "
            )
