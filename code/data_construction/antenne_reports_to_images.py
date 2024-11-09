from pdf2image import convert_from_path

tables_dict = {
    '2003': list(range(224, 233)) + list(range(235, 237)) + list(range(239, 258)) + list(range(261, 267)) + list(range(269, 276)) + list(range(279, 286)) + list(range(289, 294)),
    '2004': list(range(177, 187)) + list(range(189, 194)),
    '2005': list(range(210, 219)) + list(range(221, 255)) + list(range(256, 262)),
    '2006': list(range(185, 195)) + list(range(197, 214)) + list(range(216, 222)),
    '2007': list(range(221, 232)) + list(range(233, 241)) + list(range(243, 253)) + list(range(255, 274)) + list(range(275, 292)) + list(range(293, 296)) + list(range(297, 303)),
    '2008': list(range(179, 187)) + list(range(190, 224)) + list(range(226, 233)), 
    '2009': list(range(169, 177)) + list(range(179, 205)) + list(range(206, 213)),
    '2010': list(range(192, 200)) + list(range(205, 237)) + list(range(238, 253)) + list(range(255, 263)),
    '2011': list(range(214, 221)) + list(range(223, 230)) + list(range(233, 238)) + list(range(241, 258)) + list(range(261, 280)) + list(range(283, 302)) + list(range(305, 312)),
    '2012': list(range(162, 169)) + list(range(171, 186)) + list(range(189, 195)),
    '2013': list(range(172, 177)) + list(range(180, 213)) + list(range(215, 219)),
    '2014': list(range(180, 185)) + list(range(189, 218)) + list(range(219, 224)) + list(range(225, 227)),
    '2015': list(range(191, 196)) + list(range(199, 225)) + list(range(227, 237)) + list(range(239, 242)),
    '2016': list(range(205, 211)) + list(range(214, 245)) + list(range(246, 256)) + list(range(259, 261)),
    '2017': list(range(229, 234)) + list(range(239, 279)) + list(range(280, 290)) + list(range(293, 297)),
    '2018': list(range(212, 216)) + list(range(220, 255)) + list(range(258, 271)),
    '2019': list(range(207, 211)) + list(range(213, 234)) + list(range(236, 246)),
    '2020': list(range(234, 239)) + list(range(248, 276)) + list(range(279, 285)),
    '2021': list(range(205, 210)) + list(range(220, 243)) + list(range(246, 252)),
    '2022': list(range(219, 224)) + list(range(235, 262)) + [263] + list(range(266, 277)),
    '2023': list(range(187, 194)) + list(range(201, 221)) + list(range(225, 236))
}

for year in range(2003, 2024):
    # Path to the PDF file
    pdf_path = f'./data/source/antenne_reports/antenne-amsterdam-{year}.pdf'
    # Specify the pages to convert 
    pages_to_convert = tables_dict[str(year)]
    # Convert the specified pages to images
    images = convert_from_path(pdf_path, first_page=min(pages_to_convert), last_page=max(pages_to_convert))
    # Save or process the selected pages
    selected_images = []
    for i, page_num in enumerate(pages_to_convert):
        # Extract the image for the selected page (remembering that list indexing starts at 0)
        page_image = images[page_num - min(pages_to_convert)]
        selected_images.append(page_image)
        # Save the image
        page_image.save(f'data/intermediate/antenne_reports_to_images/antenne_amsterdam_{year}/{page_num}.png', 'PNG')



