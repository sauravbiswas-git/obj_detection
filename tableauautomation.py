from tableau_api_lib import TableauServerConnection
from tableau_api_lib.utils.querying import get_views_dataframe
import requests
import os
from PIL import Image

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

    def export_dashboard_as_image(self, view_id, filters, output_name="combined.png", output_path="output", file_format="png"):
        """
        Export a Tableau dashboard view as a single image with multiple filters.

        :param view_id: The ID of the Tableau view.
        :param filters: A list of dictionaries for filters to apply (e.g., [{"Region": "North"}, {"Region": "South"}]).
        :param output_name: Name of the combined output image file.
        :param output_path: Directory to save the image file.
        :param file_format: Format of the image file (png or jpg).
        """
        os.makedirs(output_path, exist_ok=True)
        images = []

        for filter_dict in filters:
            # Construct the URL for exporting the image
            url = f"{tableau_config['server']}/api/{tableau_config['api_version']}/sites/{self.connection.site_id}/views/{view_id}/image"

            # Add filters to the request
            params = {}
            for key, value in filter_dict.items():
                params[f"vf_{key}"] = value

            # Send the request
            response = requests.get(url, headers=self.connection.auth_headers, params=params)

            if response.status_code == 200:
                # Save each filtered image temporarily
                temp_file = os.path.join(output_path, f"temp_{value}.{file_format}")
                with open(temp_file, "wb") as file:
                    file.write(response.content)
                images.append(temp_file)
            else:
                print(f"Failed to export image for filter {filter_dict}. Status Code: {response.status_code}, Response: {response.text}")

        # Combine images into a single file
        if images:
            combined_image = self._combine_images(images, file_format)
            combined_image.save(os.path.join(output_path, output_name))
            print(f"Combined image saved at {os.path.join(output_path, output_name)}")

        # Clean up temporary files
        for image in images:
            os.remove(image)

    def _combine_images(self, image_paths, file_format):
        """Combine multiple images vertically."""
        images = [Image.open(img) for img in image_paths]
        widths, heights = zip(*(img.size for img in images))

        total_height = sum(heights)
        max_width = max(widths)

        combined_image = Image.new("RGB", (max_width, total_height), (255, 255, 255))

        y_offset = 0
        for img in images:
            combined_image.paste(img, (0, y_offset))
            y_offset += img.height

        return combined_image

    def sign_out(self):
        """Sign out from Tableau Server."""
        self.connection.sign_out()

# Example usage
if __name__ == "__main__":
    exporter = TableauDashboardExporter()

    # Replace with your workbook name and filters
    workbook_name = "Sample Workbook"
    filters = [{"Region": "North"}, {"Region": "South"}, {"Region": "East"}, {"Region": "West"}]
    output_file = "north_south_east_west.png"

    views = exporter.get_dashboard_views(workbook_name)

    # Export all views in the workbook with combined filters
    for _, view in views.iterrows():
        exporter.export_dashboard_as_image(view_id=view['id'], filters=filters, output_name=output_file)

    exporter.sign_out()
            
