#encoding: utf-8

class Foto < ActiveRecord::Base

  default_scope {order(:updated_at)}

  belongs_to :pessoa

  has_attached_file :foto,
    :default_url => "",
    :storage => :google_drive,
    # :google_drive_credentials => "#{Rails.root}/config/google_drive.yml",
    # :google_drive_options => {
    #   :public_folder_id => "0B3pvxuVmDhuDUllCTW1MNk5KcWc"
    # }, 
    :storage => :dropbox, 
    :dropbox_credentials => Rails.root.join("config/dropbox_publico.yml"),
    :dropbox_visibility => 'public',
    :styles => {
    	:thumb => "50x50#"
    }

  validates_attachment_content_type :foto, :content_type => ["image/jpg", "image/jpeg", "image/png", "image/gif"]

end
