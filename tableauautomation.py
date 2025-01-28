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

    def export_dashboard_as_png(self, view_id, filter_dict=None, output_path="output"):
        """
        Export a Tableau dashboard view as PNG.
        
        :param view_id: The ID of the Tableau view.
        :param filter_dict: A dictionary of filters to apply (e.g., {"Region": "North"}).
        :param output_path: Directory to save the PNG file.
        """
        os.makedirs(output_path, exist_ok=True)

        # Construct the URL for exporting the PNG
        url = f"{tableau_config['server']}/api/{tableau_config['api_version']}/sites/{self.connection.site_id}/views/{view_id}/image"

        # Add filters to the request
        params = {}
        if filter_dict:
            for key, value in filter_dict.items():
                params[f"vf_{key}"] = value

        # Send the request
        response = requests.get(url, headers=self.connection.auth_headers, params=params)

        if response.status_code == 200:
            # Create a unique filename based on filters
            filter_str = "_".join(f"{key}-{value}" for key, value in filter_dict.items())
            file_path = os.path.join(output_path, f"{view_id}_{filter_str}.png")
            with open(file_path, "wb") as file:
                file.write(response.content)
            print(f"Exported PNG to {file_path}")
        else:
            print(f"Failed to export PNG. Status Code: {response.status_code}, Response: {response.text}")

    def sign_out(self):
        """Sign out from Tableau Server."""
        self.connection.sign_out()

# Example usage
if __name__ == "__main__":
    exporter = TableauDashboardExporter()

    # Replace with your workbook name
    workbook_name = "Sample Workbook"

    # Define filter values for "Region"
    region_values = ["North", "South", "East", "West"]

    # Get all views in the workbook
    views = exporter.get_dashboard_views(workbook_name)

    # Export each view with all region filters
    for _, view in views.iterrows():
        for region in region_values:
            filters = {"Region": region}
            exporter.export_dashboard_as_png(view_id=view['id'], filter_dict=filters)

    exporter.sign_out()
