class Maestrano::Connector::Rails::Entity < Maestrano::Connector::Rails::EntityBase
  include Maestrano::Connector::Rails::Concerns::Entity

  # Return an array of entities from the external app

  def get_external_entities(external_entity_name, last_synchronization = nil)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Fetching #{Maestrano::Connector::Rails::External.external_name} #{external_entity_name.pluralize}")
    entities = @external_client.find(external_entity_name)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Received data: Source=#{Maestrano::Connector::Rails::External.external_name}, Entity=#{external_entity_name}, Response=#{entities}")
    entities
  end

  def get_connec_entities(last_synchronization_date)
    entities = super
    filter_connec_contacts(entities)
  end

  def create_external_entity(mapped_connec_entity, external_entity_name)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Sending create #{external_entity_name}: #{mapped_connec_entity} to #{Maestrano::Connector::Rails::External.external_name}")
    @external_client.create(external_entity_name, mapped_connec_entity)
  end

  def update_external_entity(mapped_connec_entity, external_id, external_entity_name)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Sending update #{external_entity_name} (id=#{external_id}): #{mapped_connec_entity} to #{Maestrano::Connector::Rails::External.external_name}")
    mapped_connec_entity['id'] = external_id
    @external_client.update(external_entity_name, mapped_connec_entity)
  end

  def self.id_from_external_entity_hash(entity)
    entity['id'].to_s
  end

  def self.creation_date_from_external_entity_hash(entity)
    entity['created_at']&.to_time || entity['updated_at']&.to_time || Time.now
  end

  def self.last_update_date_from_external_entity_hash(entity)
    entity['updated_at']&.to_time || Time.now
  end

  private

  def filter_connec_contacts(entities)
    # Filter contacts to return a unique entry per email per shopify requirement
    # Filter contacts to return people only
    entities
      .select { |e| e['resource_type'] == "contacts" && e.dig('email', 'address').present? && e['is_person'] }
      .group_by { |e| e.dig('email', 'address') } # Group by email
      .map do |email, contacts|
        contacts
          .sort { |a, b| (a['is_person'] ? 1 : 0) <=> (b['is_person'] ? 1 : 0) }
          .reduce({}, &:merge)
      end
    entities
  end
end
