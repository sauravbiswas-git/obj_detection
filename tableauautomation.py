from tableau_api_lib import TableauServerConnection
from tableau_api_lib.utils.querying import get_views_dataframe
import requests
import os

# Load configuration
from config import tableau_config

class TableauDashboardExporter:
    def __init__(self):
        self.connection = TableauServerConnection(tableau_config)
        self.connection.sign_in()

    def get_dashboard_views(self, workbook_name):
        """Fetch all views in a specific workbook."""
        views_df = get_views_dataframe(self.connection)
        workbook_views = views_df[views_df['workbookName'] == workbook_name]
        return workbook_views

    def export_dashboard_as_images(self, view_id, filters_list, output_path="output", file_format="png"):
        """
        Export a Tableau dashboard view as individual images for each filter combination.

        :param view_id: The ID of the Tableau view.
        :param filters_list: A list of dictionaries for filters to apply (e.g., [{"Region": "North"}, {"Region": "South"}]).
        :param output_path: Directory to save the image files.
        :param file_format: Format of the image files (png or jpg).
        """
        os.makedirs(output_path, exist_ok=True)

        for filter_dict in filters_list:
            # Construct the filename based on filter values
            filter_name = "_".join([f"{key}_{value}" for key, value in filter_dict.items()])
            file_name = f"{filter_name}.{file_format}"

            # Construct the URL for exporting the image
            url = f"{tableau_config['server']}/api/{tableau_config['api_version']}/sites/{self.connection.site_id}/views/{view_id}/image"

            # Add filters to the request
            params = {}
            for key, value in filter_dict.items():
                params[f"vf_{key}"] = value

            # Send the request
            response = requests.get(url, headers=self.connection.auth_headers, params=params)

            if response.status_code == 200:
                file_path = os.path.join(output_path, file_name)
                with open(file_path, "wb") as file:
                    file.write(response.content)
                print(f"Exported image for filters {filter_dict} to {file_path}")
            else:
                print(f"Failed to export image for filters {filter_dict}. Status Code: {response.status_code}, Response: {response.text}")

    def sign_out(self):
        """Sign out from Tableau Server."""
        self.connection.sign_out()

# Example usage
if __name__ == "__main__":
    exporter = TableauDashboardExporter()

    # Replace with your workbook name and filters
    workbook_name = "Sample Workbook"
    filters_list = [
        {"Region": "North"},
        {"Region": "South"},
        {"Region": "East"},
        {"Region": "West"},
        {"Region": "North", "Category": "Furniture"},
        {"Region": "South", "Category": "Office Supplies"}
    ]

    views = exporter.get_dashboard_views(workbook_name)

    # Export all views in the workbook with individual filters
    for _, view in views.iterrows():
        exporter.export_dashboard_as_images(view_id=view['id'], filters_list=filters_list)

    exporter.sign_out()
    
