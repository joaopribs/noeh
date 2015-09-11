#encoding: utf-8

class Foto < ActiveRecord::Base

  default_scope {order(:updated_at)}

  belongs_to :pessoa

  has_attached_file :foto,
    :default_url => "",
    :storage => :dropbox, 
    :dropbox_credentials => Rails.root.join("config/dropbox_publico.yml"),
    :dropbox_visibility => 'public',
    :path => "foto/:style/:filename", 
    :styles => {
    	:thumb => "50x50#"
    }

  validates_attachment_content_type :foto, :content_type => ["image/jpg", "image/jpeg", "image/png", "image/gif"]

end
